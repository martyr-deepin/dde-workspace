#include "pixbuf.h"
#include <gdk-pixbuf/gdk-pixbuf.h>
#include "bg_pixbuf.c"

char* generate_directory_icon(const char* p1, const char* p2, const char* p3, const char* p4)
{
#define write_to_canvas(dest, src, x, y) gdk_pixbuf_composite(src, dest, x, y, 17, 17, x, y, 1, 1, GDK_INTERP_HYPER, 255);
    GdkPixbuf *bg = gdk_pixbuf_new_from_inline(-1, dir_bg_4, TRUE, NULL);

    /*GdkPixbuf* bg = gdk_pixbuf_new_from_file("./4.png", NULL);*/
    g_assert(bg !=NULL);
    if (p1 != NULL) {
        GdkPixbuf* icon = gdk_pixbuf_new_from_file_at_scale(p1, 17, -1, TRUE, NULL);
        write_to_canvas(bg, icon, 6, 6);
        g_object_unref(icon);
    }
    if (p2 != NULL) {
        GdkPixbuf* icon = gdk_pixbuf_new_from_file_at_scale(p2, 17, -1, TRUE, NULL);
        write_to_canvas(bg, icon, 6+17, 6);
        g_object_unref(icon);
    }
    if (p3 != NULL) {
        GdkPixbuf* icon = gdk_pixbuf_new_from_file_at_scale(p3, 17, -1, TRUE, NULL);
        write_to_canvas(bg, icon, 6, 6+17);
        g_object_unref(icon);
    }
    if (p4 != NULL) {
        GdkPixbuf* icon = gdk_pixbuf_new_from_file_at_scale(p4, 17, -1, TRUE, NULL);
        write_to_canvas(bg, icon, 6+17, 6+17);
        g_object_unref(icon);
    }

    gchar* buf = NULL;
    gsize size = 0;
    GError *error = NULL;

    gdk_pixbuf_save_to_buffer(bg, &buf, &size, "png", &error, NULL);
    g_assert(buf != NULL);

    if (error != NULL) {
        g_warning("%s\n", error->message);
        g_error_free(error);
        g_free(buf);
        return NULL;
    }

    char* base64 = g_base64_encode(buf, size);
    g_free(buf);
    char* data = g_strdup_printf("data:image/png;base64,%s", base64);
    g_free(base64);

    return data;
}


char* get_data_uri_by_pixbuf(GdkPixbuf* pixbuf)
{
    gchar* buf = NULL;
    gsize size = 0;
    GError *error = NULL;

    gdk_pixbuf_save_to_buffer(pixbuf, &buf, &size, "png", &error, NULL);
    g_assert(buf != NULL);

    if (error != NULL) {
        g_warning("%s\n", error->message);
        g_error_free(error);
        g_free(buf);
        return NULL;
    }

    char* base64 = g_base64_encode(buf, size);
    g_free(buf);
    char* data = g_strdup_printf("data:image/png;base64,%s", base64);
    g_free(base64);

    return data;
}

char* get_data_uri_by_path(const char* path)
{
    GError *error = NULL;
    GdkPixbuf* pixbuf = gdk_pixbuf_new_from_file(path, &error);
    if (error != NULL) {
        g_warning("%s\n", error->message);
        g_error_free(error);
        return NULL;
    }
    return get_data_uri_by_pixbuf(pixbuf);

}
