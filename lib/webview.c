#include "webview.h"
#include "dcore.h"

GtkWidget* create_web_container()
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
    gtk_window_set_keep_above(GTK_WINDOW(window), TRUE);
    return window;
}

static bool _erase_background(GtkWidget* widget, 
        GdkEventExpose *e, gpointer data)
{ 
    cairo_t *cr;

    cr = gdk_cairo_create(gtk_widget_get_window(widget));

    cairo_set_source_rgba(cr, 0, 0, 0, 0);
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

static void
d_webview_init(DWebView *dwebview)
{
    WebKitWebView* webview = (WebKitWebView*)dwebview;
    webkit_web_view_set_transparent(webview, TRUE);

    g_signal_connect(G_OBJECT(webview), "expose-event",
            G_CALLBACK(_erase_background), NULL);

    g_signal_connect(G_OBJECT(webview), "window-object-cleared",
            G_CALLBACK(add_ddesktop_class), webview);
}

GType d_webview_get_type(void)
{
    static GType type = 0;
    if (!type) {
        printf("hhahah\n");
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
    return g_object_new(D_WEBVIEW_TYPE, NULL);
}

GtkWidget* d_webview_new_with_uri(const char* uri)
{
    /*return g_object_new(D_WEBVIEW_TYPE, "uri", uri, NULL);*/
    GtkWidget* webview = d_webview_new();
    webkit_web_view_open(WEBKIT_WEB_VIEW(webview), uri);
    return webview;
}
