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
#include "background.h"
#include "jsextension.h"


PRIVATE
char* bg_blur_pict_get_dest_path (const char* src_uri)
{
    g_debug ("[%s] bg_blur_pict_get_dest_path: src_uri=%s", __func__, src_uri);
    g_return_val_if_fail (src_uri != NULL, NULL);

    //1. calculate original picture md5
    GChecksum* checksum;
    checksum = g_checksum_new (G_CHECKSUM_MD5);
    g_checksum_update (checksum, (const guchar *) src_uri, strlen (src_uri));

    guint8 digest[16];
    gsize digest_len = sizeof (digest);
    g_checksum_get_digest (checksum, digest, &digest_len);
    g_assert (digest_len == 16);

    //2. build blurred picture path
    char* file;
    file = g_strconcat (g_checksum_get_string (checksum), ".png", NULL);
    g_checksum_free (checksum);
    char* path;
    path = g_build_filename (g_get_user_cache_dir (),
                    BG_BLUR_PICT_CACHE_DIR,
                    file,
                    NULL);
    g_free (file);

    return path;
}


PRIVATE
gboolean _set_launcher_background_aux(GdkWindow* win, const char* bg_path,
                                      double width, double height)
{
    GError* error = NULL;
    GdkPixbuf* _background_image = gdk_pixbuf_new_from_file_at_scale(bg_path,
                                                                     width,
                                                                     height,
                                                                     FALSE,
                                                                     &error);

    if (_background_image == NULL) {
        g_debug("[%s] %s\n", __func__, error->message);
        g_error_free(error);
        return FALSE;
    }

    cairo_surface_t* img_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                              width,
                                                              height);


    if (cairo_surface_status(img_surface) != CAIRO_STATUS_SUCCESS) {
        g_warning("[%s] create cairo surface fail!\n", __func__);
        g_object_unref(_background_image);
        return FALSE;
    }

    cairo_t* cr = cairo_create(img_surface);

    if (cairo_status(cr) != CAIRO_STATUS_SUCCESS) {
        g_warning("[%s] create cairo fail!\n", __func__);
        g_object_unref(_background_image);
        cairo_surface_destroy(img_surface);
        return FALSE;
    }

    gdk_cairo_set_source_pixbuf(cr, _background_image, 0, 0);
    cairo_paint(cr);
    g_object_unref(_background_image);

    cairo_pattern_t* pt = cairo_pattern_create_for_surface(img_surface);

    if (cairo_pattern_status(pt) == CAIRO_STATUS_NO_MEMORY) {
        g_warning("[%s] create cairo pattern fail!\n", __func__);
        cairo_surface_destroy(img_surface);
        cairo_destroy(cr);
        return FALSE;
    }

    gdk_window_hide(win);
    gdk_window_set_background_pattern(win, pt);
    gdk_window_show(win);

    cairo_pattern_destroy(pt);
    cairo_surface_destroy(img_surface);
    cairo_destroy(cr);

    return TRUE;
}


void set_launcher_background(GdkWindow* win, GSettings* dde_bg_g_settings,
                             double width, double height)
{
    char* bg_path = g_settings_get_string(dde_bg_g_settings, CURRENT_PCITURE);

    char* blur_path = bg_blur_pict_get_dest_path(bg_path);

    g_debug("[%s] blur pic path: %s\n", __func__, blur_path);

    if (!_set_launcher_background_aux(win, blur_path, width, height)) {
        g_debug("[%s] no blur pic, use current bg: %s\n", __func__, bg_path);
        _set_launcher_background_aux(win, bg_path, width, height);
    }

    g_free(blur_path);
    g_free(bg_path);
}


void background_changed(GSettings* settings, char* key, gpointer user_data)
{
    char* bg_path = g_settings_get_string(settings, CURRENT_PCITURE);
    char* blur_path = bg_blur_pict_get_dest_path(bg_path);
    g_free(bg_path);
    int duration = 2;
    while (!g_file_test(blur_path, G_FILE_TEST_EXISTS)) {
        if (duration > 300)
            break;
        g_usleep(duration);
        duration += 2;
    }
    if (g_file_test(blur_path, G_FILE_TEST_EXISTS)) {
        g_debug("background changed");
        js_post_message_simply("draw_background", "{\"path\": \"%s\"}", blur_path);
    }
    g_free(blur_path);
}

