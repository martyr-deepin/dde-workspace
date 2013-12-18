/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2013 ~ 2013 Liqiang Lee
 *
 * Author:      Liqiang Lee <liliqiang@linuxdeepin.com>
 * Maintainer:  Liqiang Lee <liliqiang@linuxdeepin.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 **/

#include <string.h>

#include <glib.h>
#include <glib/gstdio.h>
#include <gio/gdesktopappinfo.h>
#include <libnotify/notify.h>
#include <dbus/dbus.h>
#include <dbus/dbus-glib.h>

#include "dcore.h"
#include "dentry/entry.h"
#include "category.h"
#include "jsextension.h"

#define UNINSTALL_FAILED_TITLE "uninstall failed"
#define UNINSTALL_FAILED_SIGNAL "uninstall_failed"

#define SOFTWARE_CENTER_NAME "com.linuxdeepin.softwarecenter"
#define SOFTWARE_CENTER_OBJECT_PATH "/com/linuxdeepin/softwarecenter"
#define SOFTWARE_CENTER_INTERFACE SOFTWARE_CENTER_NAME
#define UNINSTALL_LISTEN_SIGNAL "update_signal"
#define UNINSTALL_PACKAGE_METHOD_NAME "uninstall_pkg"

#define ACTION_START_TYPE "(si)"
#define ACTION_UPDATE_TYPE "(siis)"
#define ACTION_FINISH_TYPE "(sia(sbbb))"
#define ACTION_FAILED_TYPE "(sia(sbbb)s)"


static gboolean is_uninstalling = FALSE;


static
gboolean set_uninstalling(gboolean status)
{
    // FIXME: add a lock?
    is_uninstalling = status;
    return is_uninstalling;
}


gboolean is_launcher_uninstalling()
{
    return is_uninstalling;
}


static
void notify(const char* title, const char* content)
{
    notify_init("DEEPIN_LAUNCHER");
    NotifyNotification* notification =
        notify_notification_new(title,
                                content,
                                dcore_get_theme_icon("start-here", 48));
    GError* error = NULL;
    notify_notification_show(notification, &error);
    if (error != NULL) {
        g_warning("[%s] show nitofication failed: %s", __func__, error->message);
        g_clear_error(&error);
    }
    g_object_unref(G_OBJECT(notification));
    notify_uninit();
}


DBusConnection* get_dbus(DBusBusType type)
{
    DBusError error;
    dbus_error_init(&error);

    DBusConnection* conn = dbus_bus_get(type, &error);

    if (dbus_error_is_set(&error)) {
        g_warning("[%s] Connection Error: %s", __func__, error.message);
        dbus_error_free(&error);
        return NULL;
    }

    return conn;
}


struct UninstallInfo {
    char* path;
    char* package_names;
    gboolean is_purge;
};


void destroy_uninstall_info(struct UninstallInfo* info)
{
    g_free(info->path);
    g_free(info->package_names);
    g_slice_free(struct UninstallInfo, info);
}


static
void post_failed_message(struct UninstallInfo* info)
{
    GRAB_CTX();
    JSObjectRef info_json = json_create();
    char* escaped_path = g_uri_escape_string(info->path,
                                             G_URI_RESERVED_CHARS_ALLOWED_IN_PATH,
                                             FALSE);
    char* uri = g_strdup_printf("file://%s", escaped_path);
    g_free(escaped_path);
    char* id = calc_id(uri);
    g_free(uri);
    json_append_string(info_json, "id", id);
    g_free(id);
    js_post_message(UNINSTALL_FAILED_SIGNAL, info_json);
    UNGRAB_CTX();
}


enum ACTION_TYPE {
    ACTION_START,
    ACTION_UPDATE,
    ACTION_FINISH,
    ACTION_FAILED,
    ACTION_INVALID
};


static
enum ACTION_TYPE get_action_type(const char* action_type)
{
    if (0 == g_strcmp0(action_type, ACTION_UPDATE_TYPE)) {
        return ACTION_UPDATE;
    } else if (0 == g_strcmp0(action_type, ACTION_START_TYPE)) {
        return ACTION_START;
    } else if (0 == g_strcmp0(action_type, ACTION_FINISH_TYPE)) {
        return ACTION_FINISH;
    } else if (0 == g_strcmp0(action_type, ACTION_FAILED_TYPE)) {
        return ACTION_FAILED;
    } else {
        return ACTION_INVALID;
    }
}


typedef void (*ITERATOR_FUNC)(DBusMessageIter* parent_container_iter,
                              DBusMessageIter* iter,
                              gpointer user_data);

static
void iterate_container_message(DBusMessageIter* container,
                               ITERATOR_FUNC iterate_func,
                               gpointer user_data)
{
    DBusMessageIter element_iter;
    dbus_message_iter_recurse(container, &element_iter);
    while (dbus_message_iter_get_arg_type(&element_iter) != DBUS_TYPE_INVALID) {
        iterate_func(container, &element_iter, user_data);
        dbus_message_iter_next(&element_iter);
    }
}


static
void iter_struct(DBusMessageIter* struct_iter,
                 DBusMessageIter* struct_element_iter,
                 gpointer user_data
                 )
{
    struct UninstallInfo* info = (struct UninstallInfo*)user_data;
    switch (dbus_message_iter_get_arg_type(struct_element_iter)){
    case DBUS_TYPE_STRING: {
        // first field -- action type
        DBusBasicValue value;
        dbus_message_iter_get_basic(struct_element_iter, &value);
#ifndef NDEBUG
        g_debug("first field value: %s", value.str);
#endif
        break;
    }
    case DBUS_TYPE_STRUCT: {
        // second field -- action detail
#ifndef NDEBUG
        const char* signature = dbus_message_iter_get_signature(struct_element_iter);
        g_debug("second field signature: %s", signature);
#endif
        DBusMessageIter iter;
        dbus_message_iter_recurse(struct_element_iter, &iter);

        enum ACTION_TYPE type =
            get_action_type(dbus_message_iter_get_signature(struct_element_iter));
#ifndef NDEBUG
        const char* types[] = {
            "ACTION_START",
            "ACTION_UPDATE",
            "ACTION_FINISH",
            "ACTION_FAILED",
            "ACTION_INVALUD"
        };
        g_debug("type: %s", types[type]);
#endif
        switch (type) {
        case ACTION_START:
            // (si)
            g_message("start");
            set_uninstalling(TRUE);
            break;
        case ACTION_UPDATE: {
            g_message("update");
            // (siis)
            break;
        }
        case ACTION_FINISH: {
            // (sia(sbbb))
            g_message("finish");

            // delete local file
            if (g_file_test(info->path, G_FILE_TEST_EXISTS)) {
                g_unlink(info->path);
                destroy_uninstall_info(info);
            }

            notify("uninstall finished", "uninstall finished");
            set_uninstalling(FALSE);
            g_thread_exit(NULL);
        }
        case ACTION_FAILED: {
            // (sia(sbbb)s)
            g_warning("get failed signal");
            DBusMessageIter failed_iter;
            dbus_message_iter_recurse(struct_element_iter, &failed_iter);
            g_warning("%s", dbus_message_iter_get_signature(struct_element_iter));

            while (dbus_message_iter_get_arg_type(&failed_iter) != DBUS_TYPE_ARRAY) {
                dbus_message_iter_next(&failed_iter);
            }

            dbus_message_iter_next(&failed_iter);
            g_warning("%c", dbus_message_iter_get_arg_type(&failed_iter));
            DBusBasicValue value = {0};
            dbus_message_iter_get_basic(&failed_iter, &value);

            if (value.str == NULL || value.str[0] == '\0')
                notify(UNINSTALL_FAILED_TITLE, value.str);
            else
                notify(UNINSTALL_FAILED_TITLE, "Unknown error, resources temporarily unavailable");
            post_failed_message(info);
            set_uninstalling(FALSE);
            destroy_uninstall_info(info);
            g_thread_exit(NULL);
        }
        case ACTION_INVALID:
            g_warning("INVALID");
            break;
        }

        break;
    }
    }
}


static
void iter_array(DBusMessageIter* array_iter,
                DBusMessageIter* array_element_iter,
                gpointer user_data)
{
    iterate_container_message(array_element_iter, iter_struct, user_data);
}


static
void uninstall_signal_handler(DBusConnection* conn, struct UninstallInfo* info)
{
    while (1) {
        dbus_connection_read_write(conn, 0);
        DBusMessage* message = dbus_connection_pop_message(conn);

        if (message == NULL) {
            g_usleep(100 * 1000);
            continue;
        }

        if (dbus_message_is_signal(message,
                                   SOFTWARE_CENTER_INTERFACE,
                                   UNINSTALL_LISTEN_SIGNAL)) {
            DBusMessageIter args;
            if (!dbus_message_iter_init(message, &args)) {
                dbus_message_unref(message);
                g_warning("init signal iter failed");
                return;
            }

            DBusMessageIter array_iter;
            dbus_message_iter_recurse(&args, &array_iter);

            iterate_container_message(&array_iter, iter_array, info);
        }
        dbus_message_unref(message);
    }
}


static
gboolean invoke_uninstall_method(struct UninstallInfo* info)
{
    GError* error = NULL;
    GDBusProxy* proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SYSTEM,
                                                      G_DBUS_PROXY_FLAGS_NONE,
                                                      NULL,
                                                      SOFTWARE_CENTER_NAME,
                                                      SOFTWARE_CENTER_OBJECT_PATH,
                                                      SOFTWARE_CENTER_INTERFACE,
                                                      NULL,
                                                      &error
                                                      );
    if (error != NULL) {
        g_warning("[%s] create dbus proxy failed: %s", __func__, error->message);
        g_clear_error(&error);
        return FALSE;
    }
    g_variant_unref(g_dbus_proxy_call_sync(proxy,
                                           UNINSTALL_PACKAGE_METHOD_NAME,
                                           g_variant_new("(sb)",
                                                         info->package_names,
                                                         info->is_purge),
                                           G_DBUS_CALL_FLAGS_NONE,
                                           -1,
                                           NULL,
                                           &error
                                          ));
    if (error != NULL) {
        g_warning("[%s] invoke dbus method failed: %s", __func__, error->message);
        g_clear_error(&error);
        return FALSE;
    }

    return TRUE;
}


static
void listen_update_signal(struct UninstallInfo* info)
{
    gchar *rules = g_strdup_printf("eavesdrop='true',"
                                   "type='signal',"
                                   "interface='%s',"
                                   "member='%s',"
                                   "path='%s'",
                                   SOFTWARE_CENTER_INTERFACE,
                                   UNINSTALL_LISTEN_SIGNAL,
                                   SOFTWARE_CENTER_OBJECT_PATH);

    DBusConnection* conn = get_dbus(DBUS_BUS_SYSTEM);
    if (conn == NULL) {
        return;
    }

    DBusError error;
    dbus_error_init(&error);

    dbus_bus_add_match(conn, rules, &error);
    g_free (rules);

    if (dbus_error_is_set(&error)) {
        g_warning("[%s] add match failed: %s", __func__, error.message);
        dbus_error_free(&error);
        return;
    }

    dbus_connection_flush(conn);

    uninstall_signal_handler(conn, info);
}


static
void _uninstall_package(struct UninstallInfo* info)
{
    if (invoke_uninstall_method(info))
        listen_update_signal(info);
}


static
int _get_package_names(char** package_name, int argc, char** argv, char** column_name)
{
    if (argv[0][0] != '\0') {
        g_debug("[%s] get package name: '%s'", __func__, argv[0]);
        *package_name = g_strdup(argv[0]);
    }
    return 0;
}


static
char* get_package_names_from_database(const char* basename)
{
    char* package_names = NULL;
    char* sql = g_strdup_printf("select pkg_names "
                                "from desktop "
                                "where desktop_name like \"%s\";"
                                , basename);
    search_database(get_category_name_db_path(),
                    sql,
                    (SQLEXEC_CB)_get_package_names,
                    &package_names);
    g_free(sql);
    return package_names;
}


static
char* get_package_names_from_command_line(const char* basename)
{
    GError* err = NULL;
    gint exit_status = 0;
    char* cmd[] = { "dpkg", "-S", (char*)basename, NULL};
    char* output = NULL;

    if (!g_spawn_sync(NULL, cmd, NULL,
                      G_SPAWN_SEARCH_PATH
                      | G_SPAWN_STDERR_TO_DEV_NULL,
                      NULL, NULL, &output, NULL, &exit_status, &err)) {
        g_warning("[%s] get package name failed: %s", __func__, err->message);
        g_error_free(err);
        return NULL;
    }

    if (exit_status != 0) {
        g_free(output);
        return NULL;
    }

    char* del = strchr(output, ':');
    char* package_names = g_strndup(output, del - output);
    g_free(output);

    return package_names;
}


char* get_package_names(const char* basename)
{
    char* package_names = NULL;

    package_names = get_package_names_from_database(basename);
    if (package_names != NULL) {
        g_message("[%s] get package names from database: %s", __func__, package_names);
        return package_names;
    }

    package_names = get_package_names_from_command_line(basename);

    if (package_names != NULL)
        g_message("[%s] get package names from command line: %s", __func__, package_names);

    return package_names;
}


static
void do_uninstall(gpointer _info)
{
    struct UninstallInfo* info = (struct UninstallInfo*)_info;
    char* basename = g_path_get_basename(info->path);
    info->package_names = get_package_names(basename);
    g_free(basename);

    if (info->package_names != NULL) {
        _uninstall_package(info);
    } else {
        notify(UNINSTALL_FAILED_TITLE, "package name is not found");
        post_failed_message(info);
        destroy_uninstall_info(info);
    }
}


JS_EXPORT_API
void launcher_uninstall(Entry* _item, gboolean is_purge)
{
    GDesktopAppInfo* item = G_DESKTOP_APP_INFO(_item);
    const char* filename = g_desktop_app_info_get_filename(item);
    struct UninstallInfo* info = g_slice_new(struct UninstallInfo);
    info->path = g_strdup(filename);
    info->is_purge = is_purge;
    g_thread_unref(g_thread_new("launcher_do_uninstall", (GThreadFunc)do_uninstall, info));
}

