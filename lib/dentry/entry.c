/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *               2011 ~ 2012 hooke
 *
 * Author:      snyh <snyh@snyh.org>
 *              hooke
 * Maintainer:  snyh <snyh@snyh.org>
 *              hooke
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
#include <gtk/gtk.h>
#include <glib/gi18n.h>
#include "entry.h"
#include <glib.h>
#include "jsextension.h"
#include <string.h>
#include <gio/gio.h>
#include <gio/gdesktopappinfo.h>
#include "utils.h"
#include "xdg_misc.h"
#include "fileops.h"
#include "fileops_clipboard.h"
#include "fileops_trash.h"
#include "fileops_delete.h"

ArrayContainer EMPTY_CONTAINER = {0, 0};

static GFile* _get_gfile_from_gapp(GDesktopAppInfo* info);
static ArrayContainer _normalize_array_container(ArrayContainer pfs);

#define TEST_GFILE(e, f) if (G_IS_FILE(e)) { \
    GFile* f = e;

#define TEST_GAPP(e, app) } else if (G_IS_APP_INFO(e)) { \
    GAppInfo* app = e;

#define TEST_END } else { g_warn_if_reached();}

JS_EXPORT_API
Entry* dentry_get_desktop()
{
    char* path = get_desktop_dir(FALSE);
    Entry* ret = dentry_create_by_path(path);
    g_free(path);
    return ret;
}

JS_EXPORT_API
gboolean dentry_is_native(Entry* e)
{

    if (!G_IS_FILE(e)) {
        return g_file_is_native (G_FILE(e));
    }
    return TRUE;
}
JS_EXPORT_API
double dentry_get_type(Entry* e)
{
    TEST_GFILE(e, f)
        switch (g_file_query_file_type(f, G_FILE_QUERY_INFO_NONE, NULL)) {
            case G_FILE_TYPE_REGULAR:
                return 1;
            case G_FILE_TYPE_DIRECTORY:
                {
                    char* path = g_file_get_basename(f);
                    if (g_str_has_prefix(path, DEEPIN_RICH_DIR)) {
                        g_free(path);
                        return 3;
                    } else {
                        g_free(path);
                        return 2;
                    }
                }
        case G_FILE_TYPE_SYMBOLIC_LINK:
        {
                    char* src = g_file_get_path(f);
            char* target = g_file_read_link (src, NULL);
            g_free (src);
            if (target != NULL||g_file_test(target, G_FILE_TEST_EXISTS))
            {
            GFile* target_gfile = g_file_new_for_commandline_arg(target);
            g_free(target);
            double retval = dentry_get_type(target_gfile);
            g_object_unref(target_gfile);
            if (retval == -1)
                retval = 4;
            return retval;
            }
            return 4;
        }
        //the remaining file type values.
        case G_FILE_TYPE_SPECIAL:
        case G_FILE_TYPE_MOUNTABLE:
            default:
                {
                    char* path = g_file_get_path(f);
                    g_warning("Did't know file type %s", path);
                    g_free(path);
                    return -1;
                }
        }
    TEST_GAPP(e, app)
        return 0;
    TEST_END
}

//TODO:
JS_EXPORT_API
JSObjectRef dentry_get_flags (Entry* e)
{
    JSObjectRef json = json_array_create();
    GFile* f;
    if (!G_IS_FILE(e)) {
        return json;
    }
    f = e;

    GFileInfo* info = g_file_query_info (f,
            "standard::*,access::*",
            G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS,
            NULL,
            NULL);

    if (info != NULL)
    {
        gboolean is_read_only = FALSE;
        gboolean is_symlink = FALSE;
        gboolean is_unreadable = FALSE;
        is_unreadable = !g_file_info_get_attribute_boolean(info, "access::can-read");
        is_read_only = !g_file_info_get_attribute_boolean(info, "access::can-write");
        is_symlink = g_file_info_get_is_symlink(info);
        g_object_unref(info);
        json_append_number(json, "read_only", is_read_only);
        json_append_number(json, "symbolic_link", is_symlink);
        json_append_number(json, "unreadable", is_unreadable);
    }

    return json;
}
JS_EXPORT_API
char* dentry_get_name(Entry* e)
{
    TEST_GFILE(e, f)
        return g_file_get_basename(f);
    TEST_GAPP(e, app)
        return g_strdup(g_app_info_get_name(app));
    TEST_END
}

JS_EXPORT_API
char* dentry_get_uri(Entry* e)
{
    TEST_GFILE(e, f)
        return g_file_get_uri(f);
    TEST_GAPP(e, app)
        return g_strdup_printf("file://%s", g_desktop_app_info_get_filename(G_DESKTOP_APP_INFO(app)));
    TEST_END
}

JS_EXPORT_API
char* dentry_get_icon(Entry* e)
{
    char* ret = NULL;
    TEST_GFILE(e, f)
        GFileInfo *info = g_file_query_info(f, "standard::icon", G_FILE_QUERY_INFO_NONE, NULL, NULL);
        if (info != NULL) {
            GIcon* icon = g_file_info_get_icon(info);
            ret = lookup_icon_by_gicon(icon);
        }
        g_object_unref(info);
    TEST_GAPP(e, app)
        GIcon *icon = g_app_info_get_icon(app);
        if (icon != NULL) {
            char* icon_str = g_icon_to_string(icon);
            ret = icon_name_to_path_with_check_xpm(icon_str, 48);
            g_free(icon_str);
        }
    TEST_END


    if (ret != NULL) {
        return ret;
    } else {
        return NULL; //g_strdup("not_found.png");
    }
}

JS_EXPORT_API
char* dentry_get_id(Entry* e)
{
    char* uri = dentry_get_uri(e);
    char* id = g_compute_checksum_for_string(G_CHECKSUM_MD5, uri, strlen(uri));
    g_free(uri);
    return id;
}

JS_EXPORT_API
gboolean dentry_launch(Entry* e, const ArrayContainer fs)
{
    TEST_GFILE(e, f)
        GFileInfo* info = g_file_query_info(f, G_FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE, G_FILE_QUERY_INFO_NONE, NULL, NULL);
        if (info != NULL) {
            const char* content_type = g_file_info_get_attribute_string(info, G_FILE_ATTRIBUTE_STANDARD_CONTENT_TYPE);
            GAppInfo *app  = g_app_info_get_default_for_type(content_type, FALSE);
            GList* list = g_list_append(NULL, f);
            g_app_info_launch(app, list, NULL, NULL);
            g_list_free(list);
            g_object_unref(app);
            g_object_unref(info);
        } else {
            char* path = g_file_get_path(f);
            dcore_run_command1("gvfs-open", path);
            g_free(path);
            return TRUE;
        }
    TEST_GAPP(e, app)
        ArrayContainer _fs = _normalize_array_container(fs);

        GFile** files = _fs.data;
        GList* list = NULL;
        for (size_t i=0; i<fs.num; i++) {
            list = g_list_append(list, files[i]);
        }
        gboolean ret = g_app_info_launch(app, list, NULL, NULL);
        g_list_free(list);

        for (size_t i=0; i<_fs.num; i++) {
            g_object_unref(((GObject**)_fs.data)[i]);
        }
        g_free(_fs.data);

        return ret;
    TEST_END
    return FALSE;
}



JS_EXPORT_API
ArrayContainer dentry_list_files(GFile* f)
{
    g_return_val_if_fail(g_file_query_file_type(f, G_FILE_QUERY_INFO_NONE, NULL) == G_FILE_TYPE_DIRECTORY, EMPTY_CONTAINER);

    char* dir_path = g_file_get_path(f);
    GDir* dir = g_dir_open(dir_path, 0, NULL);
    const char* child_name = NULL;
    GPtrArray* array = g_ptr_array_sized_new(1024);
    for (int i=0; NULL != (child_name = g_dir_read_name(dir)); i++) {
        char* path = g_build_filename(dir_path, child_name, NULL);
        g_ptr_array_add(array, dentry_create_by_path(path));
        g_free(path);
    }
    g_dir_close(dir);
    g_free(dir_path);

    ArrayContainer ac;
    ac.num = array->len;
    ac.data = array->pdata;
    g_ptr_array_free(array, FALSE);

    return ac;
}

JS_EXPORT_API
Entry* dentry_create_by_path(const char* path)
{
    if (g_str_has_suffix(path, ".desktop")) {
        Entry* e = g_desktop_app_info_new_from_filename(path);
        if (e != NULL) return e;
    }
    return g_file_new_for_commandline_arg(path);
}

static
GFile* _get_gfile_from_gapp(GDesktopAppInfo* info)
{
    return g_file_new_for_commandline_arg(g_desktop_app_info_get_filename(info));
}

JS_EXPORT_API
double dentry_get_mtime(Entry* e)
{
    GFile* file = NULL;
    TEST_GFILE(e, f)
        file = g_file_dup(f);
    TEST_GAPP(e, app)
        if (G_IS_DESKTOP_APP_INFO(app))
            file = _get_gfile_from_gapp((GDesktopAppInfo*)app);
    TEST_END

    guint64 time = 0;
    if (file != NULL) {
        GFileInfo* info = g_file_query_info(file, G_FILE_ATTRIBUTE_TIME_CHANGED, G_FILE_QUERY_INFO_NONE, NULL, NULL);
        time = g_file_info_get_attribute_uint64(info, G_FILE_ATTRIBUTE_TIME_CHANGED);
        g_object_unref(info);
        g_object_unref(file);
    }
    return time;
}

JS_EXPORT_API
gboolean dentry_set_name(Entry* e, const char* name)
{
    TEST_GFILE(e, f)
        GError* err = NULL;
        GFile* new_file = g_file_set_display_name(e, name, NULL, &err);
        if (err) {

        GtkWidget* dialog;
        dialog = gtk_message_dialog_new (NULL,
                         GTK_DIALOG_MODAL,
                         GTK_MESSAGE_WARNING,
                         GTK_BUTTONS_OK,
                         NULL);
        gtk_window_set_modal (GTK_WINDOW (dialog), TRUE);
        char* secondary_text = g_strdup_printf(_("The name \"%s\" is already used in this"
                             "folder. Please use a different name."),
                           name);

        g_object_set (dialog,
              "text", _("The Item could not be renamed"),
          "secondary-text", secondary_text,
          NULL);
        gtk_dialog_run (GTK_DIALOG (dialog));
        gtk_widget_destroy (dialog);
        g_free(secondary_text);
            g_error_free(err);
            return FALSE;
        } else {
            g_object_unref(new_file);
            return TRUE;
        }
    TEST_GAPP(e, app)
        const char* path = g_desktop_app_info_get_filename((GDesktopAppInfo*)app);
        return change_desktop_entry_name(path, name);
    TEST_END
}

static ArrayContainer _normalize_array_container(ArrayContainer pfs)
{
    GPtrArray* array = g_ptr_array_new();

    GFile** _array = pfs.data;
    for(size_t i=0; i<pfs.num; i++) {
        if (G_IS_DESKTOP_APP_INFO(_array[i])) {
            g_ptr_array_add(array, _get_gfile_from_gapp(((GDesktopAppInfo*)_array[i])));
        } else {
            g_ptr_array_add(array, g_object_ref(_array[i]));
        }
    }

    ArrayContainer ret;
    ret.num = pfs.num;
    ret.data = g_ptr_array_free(array, FALSE);
    return ret;
}

void dentry_move(ArrayContainer fs, GFile* dest)
{
    ArrayContainer _fs = _normalize_array_container(fs);
    fileops_move(_fs.data, _fs.num, dest);
    for (size_t i=0; i<_fs.num; i++) {
        g_object_unref(((GObject**)_fs.data)[i]);
    }
    g_free(_fs.data);
}
void dentry_copy (ArrayContainer fs, GFile* dest)
{
    ArrayContainer _fs = _normalize_array_container(fs);
    fileops_copy (_fs.data, _fs.num, dest);
    for (size_t i=0; i<_fs.num; i++) {
        g_object_unref(((GObject**)_fs.data)[i]);
    }
    g_free(_fs.data);
}

void dentry_delete_files(ArrayContainer fs, gboolean show_dialog)
{
    ArrayContainer _fs = _normalize_array_container(fs);
    fileops_confirm_delete(_fs.data, _fs.num, show_dialog);
    for (size_t i=0; i<_fs.num; i++) {
        g_object_unref(((GObject**)_fs.data)[i]);
    }
    g_free(_fs.data);
}
void dentry_trash(ArrayContainer fs)
{
    ArrayContainer _fs = _normalize_array_container(fs);
    fileops_trash (_fs.data, _fs.num);
    for (size_t i=0; i<_fs.num; i++) {
        g_object_unref(((GObject**)_fs.data)[i]);
    }
    g_free(_fs.data);
}


void dentry_clipboard_copy(ArrayContainer fs)
{
    ArrayContainer _fs = _normalize_array_container(fs);
    init_fileops_clipboard (_fs.data, _fs.num, FALSE);
    for (size_t i=0; i<_fs.num; i++) {
        g_object_unref(((GObject**)_fs.data)[i]);
    }
    g_free(_fs.data);
}

void dentry_clipboard_cut(ArrayContainer fs)
{
    ArrayContainer _fs = _normalize_array_container(fs);
    init_fileops_clipboard (_fs.data, _fs.num, TRUE);
    for (size_t i=0; i<_fs.num; i++) {
        g_object_unref(((GObject**)_fs.data)[i]);
    }
    g_free(_fs.data);
}

void dentry_clipboard_paste(GFile* dest_dir)
{
    fileops_paste (dest_dir);
}

JS_EXPORT_API
gboolean dentry_can_paste ()
{
    return ! is_clipboard_empty();
}

void dentry_confirm_trash()
{
    fileops_confirm_trash();
}

GFile* dentry_get_trash_entry()
{
    return fileops_get_trash_entry ();
}

double dentry_get_trash_count()
{
    return fileops_get_trash_count ();
}
