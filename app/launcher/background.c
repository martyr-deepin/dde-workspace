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
#include "utils.h"


#define DEFAULT_BACKGROUND_IMAGE "/usr/share/backgrounds/default_background.jpg"
// get these macros from deepin-settings-deamon/plugins/background/
#define GSD_LIBEXECDIR "/usr/lib/gnome-settings-daemon"
#define BG_GAUSSIAN_SIGMA 10.0
#define BG_GAUSSIAN_NSTEPS 10UL


GSettings* get_background_gsettings()
{
    static GSettings* settings = NULL;
    if (settings == NULL)
        settings = g_settings_new(SCHEMA_ID);
    return settings;
}


void start_gaussian_helper(const char* cur_pict_path)
{
    if (cur_pict_path == NULL)
        return;

    char* command = NULL;
    command = g_strdup_printf(GSD_LIBEXECDIR"/gsd-background-helper "
                              "%lf %lu %s",
                              BG_GAUSSIAN_SIGMA,
                              BG_GAUSSIAN_NSTEPS,
                              cur_pict_path);
    g_debug("[%s] command: %s", __func__, command);

    GError* error = NULL;
    gboolean ret = FALSE;
    if ((ret = g_spawn_command_line_async(command, &error)) == FALSE) {
        g_debug("Failed to launch '%s': '%s'", command, error->message);
        g_error_free(error);
    }

    g_debug("gsd-background-helper started");
    g_free(command);
}


PRIVATE
gboolean _set_background_aux(GdkWindow* win, const char* bg_path, double width,
                             double height)
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


void set_background(GdkWindow* win, GSettings* dde_bg_g_settings, double width,
                    double height)
{
    char* bg_path = g_settings_get_string(dde_bg_g_settings, CURRENT_PCITURE);

    if (!g_file_test(bg_path, G_FILE_TEST_EXISTS)) {
        g_warning("[%s] the image(\"%s\") is not existed, use the default image", __func__, bg_path);
        g_free(bg_path);
        bg_path = g_strdup(DEFAULT_BACKGROUND_IMAGE);
    }

    char* blur_path = bg_blur_pict_get_dest_path(bg_path);

    g_debug("[%s] blur pic path: %s\n", __func__, blur_path);

    if (!_set_background_aux(win, blur_path, width, height)) {
        g_debug("[%s] no blur pic, use current bg: %s\n", __func__, bg_path);
        _set_background_aux(win, bg_path, width, height);
    }

    g_free(blur_path);
    g_free(bg_path);
}


void background_changed(GSettings* settings, char* key, gpointer user_data G_GNUC_UNUSED)
{
    char* bg_path = g_settings_get_string(settings, key);
    if (!g_file_test(bg_path, G_FILE_TEST_EXISTS)) {
        g_warning("[%s] the background image(\"%s\") is not existed,"
                  " using the default background image(\"%s\")",
                  __func__, bg_path, DEFAULT_BACKGROUND_IMAGE);
        g_free(bg_path);
        bg_path = g_strdup(DEFAULT_BACKGROUND_IMAGE);
    }

    char* blur_path = bg_blur_pict_get_dest_path(bg_path);
    g_debug("[%s] blur_path: %s", __func__, blur_path);

    if (!g_file_test(blur_path, G_FILE_TEST_EXISTS)) {
        start_gaussian_helper(bg_path);
    }

    int duration = 2;
    while (!g_file_test(blur_path, G_FILE_TEST_EXISTS)) {
        if (duration > 400)
            break;
        g_usleep(duration);
        duration += 2;
    }

    JSObjectRef path = json_create();
    if (!g_file_test(blur_path, G_FILE_TEST_EXISTS)) {
        g_warning("[%s] the blur image(\"%s\") is not existed, "
                  "using the default background image(\"%s\")",
                  __func__, blur_path, bg_path);
        g_free(blur_path);
        blur_path = g_strdup(bg_path);
    }

    g_debug("background changed");
    json_append_string(path, "path", blur_path);
    js_post_message("draw_background", path);

    g_free(bg_path);
    g_free(blur_path);
}

