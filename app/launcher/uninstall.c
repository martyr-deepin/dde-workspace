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

#define UNINSTALL_FAILED_TITLE "uninstall failed"

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
    DBusMessageIter* array_iter = (DBusMessageIter*)user_data;
    switch (dbus_message_iter_get_arg_type(struct_element_iter)){
    case DBUS_TYPE_STRING: {
        // first field -- action type
        DBusBasicValue value;
        dbus_message_iter_get_basic(struct_element_iter, &value);
#ifndef NDEBUG
        g_debug("signature: %s, first field value: %s", dbus_message_iter_get_signature(array_iter), value.str);
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
#ifndef NDEBUG
            g_warning("start");
#endif
            // (si)
            set_uninstalling(TRUE);
            break;
        case ACTION_UPDATE: {
#ifndef NDEBUG
            g_debug("update");
#endif
            // (siis)
            g_warning("update");
            break;
        }
        case ACTION_FINISH:
#ifndef NDEBUG
            g_warning("finish");
#endif
            // (sia(sbbb))
            // notify("uninstall finished", "uninstall finished");
            set_uninstalling(FALSE);
            return;
        case ACTION_FAILED: {
#ifndef NDEBUG
            g_warning("failed");
#endif
            // (sia(sbbb)s)
            DBusMessageIter failed_iter;
            dbus_message_iter_recurse(struct_element_iter, &failed_iter);
            while (dbus_message_iter_get_arg_type(&failed_iter) != DBUS_TYPE_ARRAY) {
                dbus_message_iter_next(&failed_iter);
            }
            dbus_message_iter_next(&failed_iter);
            DBusBasicValue value;
            dbus_message_iter_get_basic(&failed_iter, &value);
            notify(UNINSTALL_FAILED_TITLE, value.str);
            set_uninstalling(FALSE);
            return;
        }
        case ACTION_INVALID:
            g_warning("INVALID");
            return;
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
    iterate_container_message(array_element_iter, iter_struct, array_iter);
}


static
void uninstall_signal_handler(DBusConnection* conn)
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

            iterate_container_message(&array_iter, iter_array, NULL);
        }
        dbus_message_unref(message);
    }
}


static
void invoke_uninstall_method(const char* pkg_name, gboolean is_purge)
{
    GDBusProxy* proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SYSTEM,
                                                      G_DBUS_PROXY_FLAGS_NONE,
                                                      NULL,
                                                      SOFTWARE_CENTER_NAME,
                                                      SOFTWARE_CENTER_OBJECT_PATH,
                                                      SOFTWARE_CENTER_INTERFACE,
                                                      NULL, NULL
                                                      );
    g_variant_unref(g_dbus_proxy_call_sync(proxy,
                                           UNINSTALL_PACKAGE_METHOD_NAME,
                                           g_variant_new("(sb)", pkg_name, is_purge),
                                           G_DBUS_CALL_FLAGS_NONE,
                                           -1,
                                           NULL,
                                           NULL
                                          ));
}


static
void listen_update_signal()
{
    gchar *rules = g_strdup_printf("eavesdrop='true',"
                                   "type='signal',"
                                   "interface='%s',"
                                   "member='%s',"
                                   "path='%s'",
                                   SOFTWARE_CENTER_INTERFACE,
                                   UNINSTALL_LISTEN_SIGNAL,
                                   SOFTWARE_CENTER_OBJECT_PATH);
    DBusError error;
    dbus_error_init(&error);

    DBusConnection* conn = get_dbus(DBUS_BUS_SYSTEM);
    dbus_bus_add_match(conn, rules, &error);
    g_free (rules);
    if (dbus_error_is_set(&error)) {
        g_warning("[%s] add match failed: %s", __func__, error.message);
        dbus_error_free(&error);
        return;
    }

    dbus_connection_flush(conn);

    g_thread_unref(g_thread_new("uninstall_software", (GThreadFunc)uninstall_signal_handler, conn));
}


static
void _uninstall_package(const char* pkg_name, gboolean is_purge)
{
    invoke_uninstall_method(pkg_name, is_purge);
    listen_update_signal();
}


char* _get_pkg_name(const char* name)
{
    GError* err = NULL;
    gint exit_status = 0;
    char* cmd[] = { "dpkg", "-S", (char*)name, NULL};
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
    char* pkg_name = g_strndup(output, del - output);
    g_free(output);

    return pkg_name;
}


/* JS_EXPORT_API */
void launcher_uninstall(const char* package_name, Entry* _item, gboolean is_purge)
{
    g_assert(package_name != NULL);
    GDesktopAppInfo* item = G_DESKTOP_APP_INFO(_item);
    const char* filename = g_desktop_app_info_get_filename(item);
    char* pkg_name = g_strdup(package_name);
    if (pkg_name[0] == '\0') {
        g_free(pkg_name);
        g_debug("[%s] package is empty", __func__);
        char* name = g_path_get_basename(filename);
        pkg_name = _get_pkg_name(name);
        g_free(name);
    }

    g_debug("[%s] the found package name is '%s'", __func__, pkg_name);


    if (pkg_name != NULL) {
        _uninstall_package(pkg_name, is_purge);
        // delete local file
        if (g_file_test(filename, G_FILE_TEST_EXISTS)) {
            g_unlink(filename);
        }
        g_free(pkg_name);
    } else {
        notify(UNINSTALL_FAILED_TITLE, "package name is not found");
    }
}

