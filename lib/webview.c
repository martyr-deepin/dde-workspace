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
#include <glib.h>
#include "dwebview.h"
#include "jsextension.h"
#include "utils.h"

static GHashTable* __views = NULL;

struct _DWebViewPriv {
    gint garbage_id;
    void (*add_js_class)(GtkWidget*);
    JSContextRef global_ctx;
};

G_DEFINE_TYPE(DWebView, d_webview, WEBKIT_TYPE_WEB_VIEW);

void workaround_gtk_theme()
{
    GtkCssProvider* provider = gtk_css_provider_get_default();
    gtk_css_provider_load_from_data(provider, "*{-GtkWindow-resize-grip-height:0;} GtkEntry:active{background:rgba(0,0,0,0);}", -1, NULL);
    gtk_style_context_add_provider_for_screen(gdk_screen_get_default(), (GtkStyleProvider*)provider, GTK_STYLE_PROVIDER_PRIORITY_USER);
}

GtkWidget* create_web_container(bool normal, bool above)
{
    GtkWidget* window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    workaround_gtk_theme();

    g_signal_connect(G_OBJECT(window), "destroy", G_CALLBACK(gtk_main_quit), NULL);
    if (!normal)
        gtk_window_set_decorated(GTK_WINDOW(window), false);

    GdkScreen *screen = gdk_screen_get_default();
    GdkVisual *visual = gdk_screen_get_rgba_visual(screen);

    if (!visual)
        visual = gdk_screen_get_system_visual(screen);
    gtk_widget_set_visual(window, visual);

    /*if (normal) {*/
        /*gtk_widget_set_size_request(window, 800, 600);*/
        /*return window;*/
    /*}*/

    /*gtk_window_maximize(GTK_WINDOW(window));*/
    /*if (above)*/
        /*gtk_window_set_keep_above(GTK_WINDOW(window), TRUE);*/
    /*else*/
        /*gtk_window_set_keep_below(GTK_WINDOW(window), FALSE);*/

    return window;
}

gboolean erase_background(GtkWidget* widget,
        cairo_t *cr, gpointer data)
{
    cairo_set_operator(cr, CAIRO_OPERATOR_CLEAR);
    cairo_paint(cr);
    return FALSE;
}


static void setup_lang(WebKitWebView* web_view)
{
    const char * const *language_names = g_get_language_names();
    if (!language_names[0])
        return;
    char const *env_lang = NULL;
    for (int i = 0; language_names[i] != NULL; ++i) {
        if (strlen(language_names[i]) == 2) {
            g_debug("%s", language_names[i]);
            env_lang = language_names[i];
            break;
        }
    }
    if (!env_lang)
        return;
    char exec_script[30] = {0};
    sprintf(exec_script, "document.body.lang=\"%s\"", env_lang);
    webkit_web_view_execute_script(web_view, exec_script);
}

gboolean invoke_js_garbage(JSGlobalContextRef* ctx)
{
    JSGarbageCollect(ctx);
    printf("garbage... %p\n", ctx);
    return TRUE;
}

static void add_ddesktop_class(DWebView *web_view,
        WebKitWebFrame *frame,
        gpointer context,
        gpointer arg3,
        gpointer user_data)
{
    printf("add_ddesktop_class\n");
    /*JSGlobalContextRef jsContext = webkit_web_frame_get_global_context(frame);*/
    if (web_view->priv->add_js_class)
        web_view->priv->add_js_class(web_view);
    g_assert(web_view->priv->garbage_id == 0);
    web_view->priv->garbage_id = g_timeout_add_seconds(3, (GSourceFunc)invoke_js_garbage, get_global_context());
}

void d_webview_set_js_init(DWebView* web_view, void (*init)(GtkWidget*))
{
    web_view->priv->add_js_class = init;
}

WebKitWebView* inspector_create(WebKitWebInspector *inspector,
        WebKitWebView *web_view, gpointer user_data)
{
    GtkWidget* win = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_widget_set_size_request(win, 800, 500);
    GtkWidget* web = webkit_web_view_new();
    gtk_container_add(GTK_CONTAINER(win), web);
    gtk_widget_show_all(win);
    return WEBKIT_WEB_VIEW(web);
}

void dwebview_show_inspector(GtkWidget* webview)
{
    WebKitWebInspector *inspector = webkit_web_view_get_inspector(
            WEBKIT_WEB_VIEW(webview));
    g_assert(inspector != NULL);
    WebKitDOMNode *node =
        (WebKitDOMNode*)webkit_web_view_get_dom_document(
                (WebKitWebView*)webview);
    webkit_web_inspector_inspect_node(inspector, node);
}

static bool webview_key_release_cb(GtkWidget* webview,
        GdkEvent* event, gpointer data)
{
    GdkEventKey *ev = (GdkEventKey*)event;
    switch (ev->keyval) {
        case GDK_KEY_F5:
            webkit_web_view_reload(WEBKIT_WEB_VIEW(webview));
            break;
        case GDK_KEY_F12:
            {
                dwebview_show_inspector(webview);
                break;
            }
    }

    return FALSE;
}


static void
d_webview_init(DWebView *dwebview)
{
    dwebview->priv = G_TYPE_INSTANCE_GET_PRIVATE(dwebview, D_WEBVIEW_TYPE, DWebViewPriv);
    dwebview->priv->add_js_class = NULL;
    dwebview->priv->garbage_id = 0;
    dwebview->priv->global_ctx = webkit_web_frame_get_global_context(webkit_web_view_get_main_frame(dwebview));

    WebKitWebView* webview = (WebKitWebView*)dwebview;
    webkit_web_view_set_transparent(webview, TRUE);

    g_signal_connect(G_OBJECT(webview), "document-load-finished",
            G_CALLBACK(setup_lang), NULL);

    g_signal_connect(G_OBJECT(webview), "window-object-cleared",
            G_CALLBACK(add_ddesktop_class), webview);

#ifndef NDEBUG
    g_signal_connect(webview, "key-release-event",
            G_CALLBACK(webview_key_release_cb), NULL);

    WebKitWebInspector *inspector = webkit_web_view_get_inspector(
            WEBKIT_WEB_VIEW(webview));
    g_assert(inspector != NULL);
    g_signal_connect_after(inspector, "inspect-web-view",
            G_CALLBACK(inspector_create), NULL);
#endif

    g_hash_table_insert(__views, "main", dwebview);
}


static void
d_webview_dispose(GObject* webview)
{
    int id = D_WEBVIEW(webview)->priv->garbage_id;
    printf("webview:%p disposed %d\n", webview, id);
    if (id > 0)
        g_source_remove(id);
    D_WEBVIEW(webview)->priv->garbage_id = 0;
    G_OBJECT_CLASS(d_webview_parent_class)->dispose(webview);
}

JSGlobalContextRef get_global_context()
{
    const char* name = "main";
    DWebView* webview = g_hash_table_lookup(__views, name);
    if (webview == NULL)
        webview = g_hash_table_lookup(__views, "main");
    g_assert(webview != NULL);
    return webview->priv->global_ctx;
}
JSGlobalContextRef get_global_context_by_webview(GtkWidget* webview)
{
    return D_WEBVIEW(webview)->priv->global_ctx;
}

void d_webview_class_init(DWebViewClass* klass)
{
    g_assert(__views == NULL);
    __views = g_hash_table_new(g_str_hash, g_str_equal);
    GObjectClass *gobject_class = G_OBJECT_CLASS (klass);
    gobject_class->dispose = d_webview_dispose;

    g_type_class_add_private(klass, sizeof(DWebViewPriv));

    char* cfg_path = g_build_filename(g_get_user_config_dir(), "deepin-desktop", NULL);
    webkit_set_web_database_directory_path(cfg_path);
    g_free(cfg_path);
}

GtkWidget* d_webview_new()
{
    GtkWidget* webview = g_object_new(D_WEBVIEW_TYPE, NULL);
    WebKitWebSettings *setting = webkit_web_view_get_settings(WEBKIT_WEB_VIEW(webview));
    g_object_set(G_OBJECT(setting),
            /*"enable-default-context-menu", FALSE,*/
            "enable-developer-extras", TRUE,
            /*"html5-local-storage-database-path", cfg_path,*/
            "enable-plugins", FALSE,
            "javascript-can-access-clipboard", TRUE,
            NULL);

    return webview;
}

GtkWidget* d_webview_new_with_uri(const char* uri)
{
    GtkWidget* webview = d_webview_new();
    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview), uri);
    return webview;
}

void monitor_resource_file(const char* app, GtkWidget* webview)
{
    char* p_js= g_build_filename(RESOURCE_DIR, app, "js", NULL);
    char* p_css = g_build_filename(RESOURCE_DIR, app, "css", NULL);
    GFile* f_js = g_file_new_for_path(p_js);
    GFile* f_css = g_file_new_for_path(p_css);

    g_free(p_js);
    g_free(p_css);

    GFileMonitor* m_js = g_file_monitor_directory(f_js,  G_FILE_MONITOR_NONE, NULL, NULL);
    GFileMonitor* m_css = g_file_monitor_directory(f_css,  G_FILE_MONITOR_NONE, NULL, NULL);
    g_file_monitor_set_rate_limit(m_js, 200);
    g_file_monitor_set_rate_limit(m_css, 200);
    g_signal_connect_object(m_js, "changed", G_CALLBACK(webkit_web_view_reload), webview, G_CONNECT_SWAPPED);
    g_signal_connect_object(m_css, "changed", G_CALLBACK(webkit_web_view_reload), webview, G_CONNECT_SWAPPED);
}

