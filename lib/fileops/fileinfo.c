#include <glib.h>
#include "jsextension.h"
#include <string.h>
#include <gio/gio.h>

JS_EXPORT_API
char* dfile_get_basename(GFile* f)
{
    g_assert(G_IS_FILE(f));
    return g_file_get_basename(f);
}


JS_EXPORT_API
char* dfile_get_id(GFile* f)
{
    g_assert(f != NULL);
    char* path = g_file_get_path(f);
    char* id = g_compute_checksum_for_string(G_CHECKSUM_MD5, path, strlen(path));
    g_free(path);
    return id;
}

JS_EXPORT_API
ArrayContainer dfile_list_files(GFile* f)
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
GFile* dfile_create_by_path(const char* path)
{
    return g_file_new_for_path(path);
}
