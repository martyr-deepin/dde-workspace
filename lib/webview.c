#include "webview.h"
#include "ddesktop.h"
#include "utils.h"
#include "LauncherInspectorWindow.h"

GtkWidget* create_web_container(bool above)
{
    GtkWidget* window = gtk_window_new(GTK_WINDOW_TOPLEVEL);

    g_signal_connect(G_OBJECT(window), "destroy", G_CALLBACK(gtk_main_quit), NULL);
    gtk_window_set_decorated(GTK_WINDOW(window), false);

    GdkScreen *screen = gdk_screen_get_default();
    GdkVisual *visual = gdk_screen_get_rgba_visual(screen);

    if (!visual)
        visual = gdk_screen_get_system_visual(screen);
    gtk_widget_set_visual(window, visual);

    gtk_window_maximize(GTK_WINDOW(window));
    if (above)
        gtk_window_set_keep_above(GTK_WINDOW(window), TRUE);
    else
        gtk_window_set_keep_below(GTK_WINDOW(window), TRUE);

    return window;
}

static bool _erase_background(GtkWidget* widget, 
        GdkEventExpose *e, gpointer data)
{ 
    cairo_t *cr;

    cr = gdk_cairo_create(gtk_widget_get_window(widget));

    cairo_set_source_rgba(cr, 0, 0, 0, 1.0);
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
    cairo_paint(cr);

    cairo_destroy(cr);

    return FALSE;
}

static void add_ddesktop_class(WebKitWebView *web_view,
        WebKitWebFrame *frame, 
        gpointer context, 
        gpointer arg3, 
        gpointer user_data)
{
    JSGlobalContextRef jsContext = webkit_web_frame_get_global_context(frame);

    struct DDesktopData* data = g_new0(struct DDesktopData, 1);
    data->webview = GTK_WIDGET(web_view);
    data->tmp_region = cairo_region_create();
    data->global_region = cairo_region_create();
    init_ddesktop(jsContext, data);
}


static GtkWidget *inspectorInspectWebViewCb(WebKitWebInspector *inspector, WebKitWebView *webView, GtkWindow* window)
{
    GtkWidget *inspectorWindow = launcherInspectorWindowNew(inspector, window);
    return GTK_WIDGET(launcherInspectorWindowGetWebView(LAUNCHER_INSPECTOR_WINDOW(inspectorWindow)));
}

static bool webview_key_release_cb(GtkWidget* webview, 
        GdkEvent* event, gpointer data)
{
    GtkWidget* insp = NULL;
    GdkEventKey *ev = (GdkEventKey*)event;
    switch (ev->keyval) {
        case GDK_KEY_F5: 
            webkit_web_view_reload(WEBKIT_WEB_VIEW(webview));
            break;
        case GDK_KEY_F12:
            insp = inspectorInspectWebViewCb(
                    webkit_web_view_get_inspector(WEBKIT_WEB_VIEW(webview)),
                    WEBKIT_WEB_VIEW(webview), 
                    NULL);
            gtk_widget_show(insp);
            break;
    }

    return FALSE;
}

static void
d_webview_init(DWebView *dwebview)
{
    WebKitWebView* webview = (WebKitWebView*)dwebview;
    webkit_web_view_set_transparent(webview, TRUE);

    g_signal_connect(G_OBJECT(webview), "draw", G_CALLBACK(_erase_background), NULL);

    g_signal_connect(G_OBJECT(webview), "window-object-cleared",
            G_CALLBACK(add_ddesktop_class), webview);
    g_signal_connect_after(webkit_web_view_get_inspector(webview),
            "inspect-web-view", G_CALLBACK(inspectorInspectWebViewCb), NULL);
    g_signal_connect(webview, "key-release-event", G_CALLBACK(webview_key_release_cb), NULL);

}

GType d_webview_get_type(void)
{
    static GType type = 0;
    if (!type) {
        static const GTypeInfo info = {
            sizeof(DWebViewClass),
            NULL,
            NULL,
            NULL,//(GClassInitFunc)d_webview_class_init,
            NULL,
            NULL,
            sizeof(DWebView),
            0,
            (GInstanceInitFunc)d_webview_init,
        };

        type = g_type_register_static(WEBKIT_TYPE_WEB_VIEW,  "DWebView", &info, 0);
    }
    return type;
}



GtkWidget* d_webview_new()
{
    GtkWidget* webview = g_object_new(D_WEBVIEW_TYPE, NULL);
    WebKitWebSettings *setting = webkit_web_view_get_settings(WEBKIT_WEB_VIEW(webview));

    char* config_path = get_config_path("deepin-desktop");
    g_object_set(G_OBJECT(setting), 
            /*"enable-default-context-menu", FALSE,*/
            "enable-developer-extras", TRUE, 
            "html5-local-storage-database-path", config_path,
            NULL);
    webkit_set_web_database_directory_path(config_path);
    g_free(config_path);

    return webview;
}

GtkWidget* d_webview_new_with_uri(const char* uri)
{
    /*return g_object_new(D_WEBVIEW_TYPE, "uri", uri, NULL);*/
    GtkWidget* webview = d_webview_new();
    webkit_web_view_load_uri(WEBKIT_WEB_VIEW(webview), uri);
    return webview;
}
