#include "entry.h"
#include <glib.h>
#include "jsextension.h"
#include <string.h>
#include <gio/gio.h>
#include <gio/gdesktopappinfo.h>
#include "utils.h"
#include "xdg_misc.h"


#define TEST_GFILE(e, f) if (G_IS_FILE(e)) { \
    GFile* f = e;

#define TEST_GAPP(e, app) } else if (G_IS_APP_INFO(e)) { \
    GAppInfo* app = e;

#define TEST_END } else { g_assert_not_reached();}

JS_EXPORT_API
double dentry_get_type(Entry* e)
{
    TEST_GFILE(e, f)
        switch (g_file_query_file_type(f, G_FILE_QUERY_INFO_NONE, NULL)) {
            case G_FILE_TYPE_DIRECTORY:
                return 2;
            case G_FILE_TYPE_REGULAR:
                return 1;
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
char* dentry_get_path(Entry* e)
{
    TEST_GFILE(e, f)
        return g_file_get_path(f);
    TEST_GAPP(e, app)
        return g_strdup(g_desktop_app_info_get_filename(G_DESKTOP_APP_INFO(app)));
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
        char* icon_str = g_icon_to_string(icon);
        ret = icon_name_to_path(icon_str, 48);
        g_free(icon_str);
    TEST_END


    if (ret != NULL) {
        return ret;
    } else {
        return g_strdup("not_found.png");
    }
}

JS_EXPORT_API
char* dentry_get_id(Entry* e)
{
    char* path = dentry_get_path(e);
    char* id = g_compute_checksum_for_string(G_CHECKSUM_MD5, path, strlen(path));
    g_free(path);
    return id;
}

JS_EXPORT_API
gboolean dentry_launch(Entry* e, ArrayContainer fs)
{
//TODO:  parse fs
    TEST_GFILE(e, f)
        char* path = g_file_get_path(f);
        dcore_run_command1("gvfs-open", path);
        g_free(path);
        return TRUE;
    TEST_GAPP(e, app)
        return g_app_info_launch(app, NULL, NULL, NULL);
    TEST_END
    return FALSE;
}


JS_EXPORT_API
ArrayContainer dentry_list_files(GFile* f)
{
    g_assert(g_file_query_file_type(f, G_FILE_QUERY_INFO_NONE, NULL) == G_FILE_TYPE_DIRECTORY);

    char* path = g_file_get_path(f);
    GDir* dir = g_dir_open(path, 0, NULL);
    g_free(path);
    const char* child_name = NULL;
    GPtrArray* array = g_ptr_array_sized_new(1024);
    for (int i=0; NULL != (child_name = g_dir_read_name(dir)); i++) {
        GFile* child = g_file_get_child(f, child_name);
        g_ptr_array_add(array, child);
    }
    g_dir_close(dir);

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

    return g_file_new_for_path(path);
}
