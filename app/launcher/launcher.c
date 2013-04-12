/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
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
#include "xdg_misc.h"
#include <gtk/gtk.h>
#include "dwebview.h"
#include "dentry/entry.h"
#include "utils.h"
#include "X_misc.h"
#include "i18n.h"
#include "category.h"
#include "dbus.h"
#include <gio/gdesktopappinfo.h>
#define DOCK_HEIGHT 30
#define SCHEMA_ID "com.deepin.dde.background"
#define CURRENT_PCITURE "current-picture"
#define BG_BLUR_PICT_CACHE_DIR "gaussian-background"


static GtkWidget* container = NULL;
static GdkScreen* screen = NULL;
static int screen_width;
static int screen_height;
static GSettings* dde_bg_g_settings = NULL;
static gboolean is_debug;

static void get_screen_info()
{
    screen = gdk_screen_get_default();
    screen_width = gdk_screen_get_width(screen);
    screen_height = gdk_screen_get_height(screen);
}

static
gboolean _set_launcher_background_aux(GdkWindow* win, const char* bg_path)
{
    GError* error = NULL;
    GdkPixbuf* _background_image = gdk_pixbuf_new_from_file_at_scale(bg_path,
                                                                    screen_width,
                                                                    screen_height,
                                                                    FALSE,
                                                                    &error);

    if (_background_image == NULL) {
        g_debug("%s\n", error->message);
        g_error_free(error);
        return FALSE;
    }

    cairo_surface_t* img_surface = cairo_image_surface_create(CAIRO_FORMAT_ARGB32,
                                                              screen_width,
                                                              screen_height);


    if (cairo_surface_status(img_surface) != CAIRO_STATUS_SUCCESS) {
        g_warning("create cairo surface fail!\n");
        g_object_unref(_background_image);
        return FALSE;
    }

    cairo_t* cr = cairo_create(img_surface);

    if (cairo_status(cr) != CAIRO_STATUS_SUCCESS) {
        g_warning("create cairo fail!\n");
        g_object_unref(_background_image);
        cairo_surface_destroy(img_surface);
        return FALSE;
    }

    gdk_cairo_set_source_pixbuf(cr, _background_image, 0, 0);
    cairo_paint(cr);
    g_object_unref(_background_image);

    cairo_pattern_t* pt = cairo_pattern_create_for_surface(img_surface);

    if (cairo_pattern_status(pt) == CAIRO_STATUS_NO_MEMORY) {
        g_warning("create cairo pattern fail!\n");
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
static
char* bg_blur_pict_get_dest_path (const char* src_uri)
{
    g_debug ("bg_blur_pict_get_dest_path: src_uri=%s", src_uri);
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

static
void _set_launcher_background(GdkWindow* win)
{
    dde_bg_g_settings = g_settings_new(SCHEMA_ID);
    char* bg_path = g_settings_get_string(dde_bg_g_settings, CURRENT_PCITURE);

    char* blur_path = bg_blur_pict_get_dest_path(bg_path);

    if (is_debug)
        g_warning("blur pic path: %s\n", blur_path);

    if (!_set_launcher_background_aux(win, blur_path)) {
        if (is_debug)
            g_warning("no blur pic, use current bg: %s\n", bg_path);
        _set_launcher_background_aux(win, bg_path);
    }
    g_object_unref(dde_bg_g_settings);
    g_free(blur_path);
    g_free(bg_path);
}

static
void _do_im_commit(GtkIMContext *context, gchar* str)
{
    JSObjectRef json = json_create();
    json_append_string(json, "Content", str);
    js_post_message("im_commit", json);
}

static
void _update_size(GdkScreen *screen, GtkWidget* conntainer)
{
    gtk_widget_set_size_request(container, screen_width, screen_height);
}

static
void _on_realize(GtkWidget* container)
{
    _update_size(screen, container);
    g_signal_connect(screen, "size-changed", G_CALLBACK(_update_size), container);
}


void launcher_show()
{
    GdkWindow* w = gtk_widget_get_window(container);
    gdk_window_show(w);
}

void launcher_hide()
{
    GdkWindow* w = gtk_widget_get_window(container);
    gdk_window_hide(w);
}

int main(int argc, char* argv[])
{
    is_debug = FALSE;
    if (argc > 1 && g_str_equal("-d", argv[1]))
            is_debug = TRUE;

    if (is_application_running("launcher.app.deepin")) {
        if (argc > 1 && g_str_equal("--toggle", argv[1])) {
            system("killall launcher");
        } else {
            g_warning("another instance of application launcher is running...\n");
        }
        return 0;
    }

    init_i18n();
    gtk_init(&argc, &argv);
    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);
    gtk_window_set_wmclass(GTK_WINDOW(container), "dde-launcher", "DDELauncher");

    get_screen_info();
    set_default_theme("Deepin");
    set_desktop_env_name("Deepin");

    GtkWidget *webview = d_webview_new_with_uri(GET_HTML_PATH("launcher"));

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));

    g_signal_connect(container, "realize", G_CALLBACK(_on_realize), NULL);
    g_signal_connect (container, "destroy", G_CALLBACK(gtk_main_quit), NULL);

    gtk_widget_realize(container);
    gtk_widget_realize(webview);

    _set_launcher_background(gtk_widget_get_window(webview));

    GdkWindow* gdkwindow = gtk_widget_get_window(container);
    GdkRGBA rgba = {0, 0, 0, 0.0 };
    gdk_window_set_background_rgba(gdkwindow, &rgba);

    gdk_window_set_skip_taskbar_hint(gdkwindow, TRUE);
    gdk_window_set_skip_pager_hint(gdkwindow, TRUE);

    /* GtkIMContext* im_context = gtk_im_multicontext_new(); */
    /* gtk_im_context_set_client_window(im_context, gdkwindow); */
    /* GdkRectangle area = {0, 1700, 100, 30}; */
    /* gtk_im_context_set_cursor_location(im_context, &area); */
    /* gtk_im_context_focus_in(im_context); */
    /* g_signal_connect(im_context, "commit", G_CALLBACK(_do_im_commit), NULL); */

    setup_dbus_service();
    monitor_resource_file("launcher", webview);
    gtk_widget_show_all(container);
    gtk_main();
    return 0;
}

JS_EXPORT_API
void launcher_exit_gui()
{
    gtk_main_quit();
}

JS_EXPORT_API
void launcher_notify_workarea_size()
{
    js_post_message_simply("workarea_changed",
            "{\"x\":0, \"y\":0, \"width\":%d, \"height\":%d}",
            screen_width, screen_height);
}

/**
 * @brief - key: the category id
 *          value: a list of applications id (md5 basename of path)
 */
static GHashTable* _category_table = NULL;


static
void _append_to_category(const char* path, GList* cs)
{
    if (_category_table == NULL) {
        //TODO new_with_full
        _category_table = g_hash_table_new(g_direct_hash, g_direct_equal);
    }

    GPtrArray* l = NULL;

    for (GList* iter = g_list_first(cs); iter != NULL; iter = g_list_next(iter)) {
        gpointer id = iter->data;
        l = g_hash_table_lookup(_category_table, id);
        if (l == NULL) {
            l = g_ptr_array_new_with_free_func(g_free);
            g_hash_table_insert(_category_table, id, l);
        }

        g_ptr_array_add(l, g_strdup(path));
    }
}

static
void _record_category_info(const char* id, GDesktopAppInfo* info)
{
    GList* categories = get_deepin_categories(info);
    _append_to_category(id, categories);
    g_list_free(categories);
}

static
JSObjectRef _init_category_table()
{
    JSObjectRef items = json_array_create();
    GList* app_infos = g_app_info_get_all();

    GList* iter = app_infos;
    for (gsize i=0, skip=0; iter != NULL; i++, iter = g_list_next(iter)) {

        GAppInfo* info = iter->data;
        if (!g_app_info_should_show(info)) {
            skip++;
            continue;
        }

        char* id = dentry_get_id(info);
        _record_category_info(id, G_DESKTOP_APP_INFO(info));
        g_free(id);

        json_array_insert_nobject(items, i - skip,
                info, g_object_ref, g_object_unref);

        g_object_unref(info);
    }

    g_list_free(app_infos); //the element of GAppInfo should free by JSRunTime not here!

    return items;
}


JS_EXPORT_API
JSObjectRef launcher_get_items_by_category(double _id)
{
    int id = _id;
    if (id == -1)
        return _init_category_table();

    JSObjectRef items = json_array_create();

    GPtrArray* l = g_hash_table_lookup(_category_table, GINT_TO_POINTER(id));
    if (l == NULL) {
        return items;
    }

    JSContextRef cxt = get_global_context();
    for (int i = 0; i < l->len; ++i) {
        const char* path = g_ptr_array_index(l, i);
        if (is_debug)
            g_warning("insert category(name: %s, id: %d) into category(id: %d)\n", path, i, id);
        json_array_insert(items, i, jsvalue_from_cstr(cxt, path));
    }

    return items;
}

static
gboolean _pred(const gchar* lhs, const gchar* rhs)
{
    return g_strrstr(lhs, rhs) != NULL;
}

typedef gboolean (*Prediction)(const gchar*, const gchar*);

static
double _get_weight(const char* src, const char* key, Prediction pred, double weight)
{
    if (src == NULL) {
        return 0.0;
    }

    char* k = g_utf8_casefold(src, -1);
    double ret = pred(k, key) ? weight : 0.0;
    g_free(k);
    return ret;
}

#define FILENAME_WEIGHT 0.3
#define GENERIC_NAME_WEIGHT 0.01
#define KEYWORD_WEIGHT 0.1
#define CATEGORY_WEIGHT 0.01
#define NAME_WEIGHT 0.01
#define DISPLAY_NAME_WEIGHT 0.1
#define DESCRIPTION_WEIGHT 0.01
#define EXECUTABLE_WEIGHT 0.05

JS_EXPORT_API
double launcher_is_contain_key(GDesktopAppInfo* info, const char* key)
{
    double weight = 0.0;

    /* desktop file information */
    const char* path = g_desktop_app_info_get_filename(info);
    char* basename = g_path_get_basename(path);
    *strchr(basename, '.') = '\0';
    weight += _get_weight(basename, key, _pred, FILENAME_WEIGHT);
    g_free(basename);

    const char* gname = g_desktop_app_info_get_generic_name(info);
    weight += _get_weight(gname, key, _pred, GENERIC_NAME_WEIGHT);

    const char* const* keys = g_desktop_app_info_get_keywords(info);
    if (keys != NULL) {
        size_t n = g_strv_length((char**)keys);
        for (size_t i=0; i<n; i++) {
            weight += _get_weight(keys[i], key, _pred, KEYWORD_WEIGHT);
        }
    }

    const char* categories = g_desktop_app_info_get_categories(info);
    if (categories) {
        gchar** category_names = g_strsplit(categories, ";", -1);
        gsize len = g_strv_length(category_names) - 1;
        for (gsize i = 0; i < len; ++i) {
            weight += _get_weight(category_names[i], key, _pred, CATEGORY_WEIGHT);
        }
        g_strfreev(category_names);
    }

    /* application information */
    const char* name = g_app_info_get_name((GAppInfo*)info);
    weight += _get_weight(name, key, _pred, NAME_WEIGHT);

    const char* dname = g_app_info_get_display_name((GAppInfo*)info);
    weight += _get_weight(dname, key, _pred, DISPLAY_NAME_WEIGHT);

    const char* desc = g_app_info_get_description((GAppInfo*)info);
    weight += _get_weight(desc, key, _pred, DESCRIPTION_WEIGHT);

    const char* exec = g_app_info_get_executable((GAppInfo*)info);
    weight += _get_weight(exec, key, _pred, EXECUTABLE_WEIGHT);

    return weight;
}

static
void print(gpointer data, gpointer user_data)
{
    printf("%s\n", (const char *)data);
}

static
void _insert_category(JSObjectRef categories, int array_index, int id, const char* name)
{
    JSObjectRef item = json_create();
    if (is_debug)
        g_warning("insert category(name: %s, id: %d) into category list\n", name, id);
    json_append_number(item, "ID", id);
    json_append_string(item, "Name", name);
    json_array_insert(categories, array_index, item);
}

static
void _record_categories(JSObjectRef categories, const char* names[], int num)
{
    int index = 1;
    for (int i = 0; i < num; ++i) {
        if (g_hash_table_lookup(_category_table, GINT_TO_POINTER(i))) {
            _insert_category(categories, index++, i, names[i]);
        }
    }

    if (g_hash_table_lookup(_category_table, GINT_TO_POINTER(OTHER_CATEGORY_ID))) {
        int last_index = num - 1;
        _insert_category(categories, index, OTHER_CATEGORY_ID, names[last_index]);
    }
}

JS_EXPORT_API
JSObjectRef launcher_get_categories()
{
    JSContextRef cxt = get_global_context();
    JSObjectRef categories = json_array_create();

    _insert_category(categories, 0, ALL_CATEGORY_ID, _("all"));

    const char* names[] = {_("internet"), _("multimedia"), _("games"),
        _("graphics"), _("productivity"), _("industry"), _("education"),
        _("development"), _("system"), _("utilities"), _("other")};

    int category_num = 0;
    const GPtrArray* infos = get_all_categories_array();

    if (infos == NULL) {
        category_num = G_N_ELEMENTS(names) - 1;
    } else {
        category_num = infos->len;
        for (int i = 0; i < category_num; ++i) {
            names[i] = (char*)g_ptr_array_index(infos, i);
        }
    }

    _record_categories(categories, names, category_num);
    return categories;
}

JS_EXPORT_API
GFile* launcher_get_desktop_entry()
{
    char* desktop = get_desktop_dir(FALSE);
    GFile* r = g_file_new_for_path(desktop);
    g_free(desktop);
    return r;
}

