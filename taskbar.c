#include <gtk/gtk.h>
#include <gdk/gdk.h>
#include <gdk/gdkx.h>
#include <webkit/webkit.h>
#include <JavaScriptCore/JavaScript.h>
#include <JavaScriptCore/JSObjectRef.h>
#include <JavaScriptCore/JSValueRef.h>
#include <sys/utsname.h>
#include <xcb/xcb.h>
#include <stdlib.h>

xcb_connection_t *connection;
xcb_window_t traywin;


static void _show_region(int x, int y, int width, int height);

static void myclass_init_cb(JSContextRef ctx, JSObjectRef object)
{
    printf("class_init\n");
}

static void myclass_finalize_cb(JSObjectRef object)
{
    printf("class_finalize\n");
}

static JSValueRef show_region(JSContextRef context,
        JSObjectRef function, JSObjectRef thisObject,
        size_t argumentCount, const JSValueRef arguments[],
        JSValueRef *exception)
{

    int* prv = JSObjectGetPrivate(thisObject);
    printf("private:%d\n", *prv);
    JSStringRef string = JSStringCreateWithUTF8CString("OK");
    int x = JSValueToNumber(context, arguments[0], NULL);
    int y = JSValueToNumber(context, arguments[1], NULL);
    int width = JSValueToNumber(context, arguments[2], NULL);
    int height = JSValueToNumber(context, arguments[3], NULL);
    printf("x:%d, y:%d, width:%d, height:%d\n", x, y, width, height);
    _show_region(x, y, width, height);
    return JSValueMakeNull(context);
}

static const JSStaticFunction class_staticfuncs[] = {
    { "allow_rect", show_region, kJSPropertyAttributeReadOnly },
    { NULL, NULL, 0}
};

static const JSClassDefinition class_def = {
    0, 
    kJSClassAttributeNone,
    "TestClass",
    NULL,
    NULL,
    class_staticfuncs,
    NULL, //myclass_init_cb,
    NULL, //myclass_finalize_cb,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
};

int tmp = 3;

static void addJSClasses(JSGlobalContextRef context)
{
    JSClassRef classDef = JSClassCreate(&class_def);
    JSObjectRef classObj = JSObjectMake(context, classDef, (void*)&tmp);
    printf("tmp addr:%p\n", &tmp);
    JSObjectRef globalObj = JSContextGetGlobalObject(context);
    JSStringRef str = JSStringCreateWithUTF8CString("DDesktop");
    JSObjectSetProperty(context, globalObj, str, classObj,
            kJSClassAttributeNone, NULL);
}

static void window_object_cleared_cb(WebKitWebView *web_view,
        WebKitWebFrame *frame, gpointer context, 
        gpointer arg3, gpointer user_data)
{
    JSGlobalContextRef jsContext = webkit_web_frame_get_global_context(frame);
    addJSClasses(jsContext);
}

static GtkWidget* main_window;
static WebKitWebView* web_view;

static bool erase_background(GtkWidget* widget, 
        GdkEventExpose *e, gpointer data)
{ 
    cairo_t *cr;

    cr = gdk_cairo_create(widget->window);

    cairo_set_source_rgba(cr, 0, 0, 0, 0);
    cairo_set_operator(cr, CAIRO_OPERATOR_SOURCE);
    cairo_paint(cr);

    cairo_destroy(cr);

    return FALSE;
}

static void send_message(GtkWidget* widget, GdkEvent *e, gpointer data)
{
    printf("foucs-changed\n");
}

static GtkWidget* create_browser()
{
    GtkWidget* scrolled_window = gtk_scrolled_window_new(NULL, NULL);
    gtk_scrolled_window_set_policy(GTK_SCROLLED_WINDOW(scrolled_window),
            GTK_POLICY_AUTOMATIC, GTK_POLICY_AUTOMATIC);
    web_view = WEBKIT_WEB_VIEW(webkit_web_view_new());
    webkit_web_view_set_transparent(web_view, TRUE);
    gtk_container_add(GTK_CONTAINER(scrolled_window), GTK_WIDGET(web_view));

    g_signal_connect(G_OBJECT(web_view), "window-object-cleared",
            G_CALLBACK(window_object_cleared_cb), web_view);
    g_signal_connect(G_OBJECT(web_view), "expose-event",
            G_CALLBACK(erase_background), web_view);
    g_signal_connect(G_OBJECT(web_view), "focus-out-event",
            G_CALLBACK(send_message), web_view);

    return scrolled_window;
}

GtkWidget* window;
static GtkWidget* create_window()
{
    window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    gtk_window_set_default_size(GTK_WINDOW(window), 500, 500);
    g_signal_connect(G_OBJECT(window), "destroy", G_CALLBACK(gtk_main_quit), NULL);
    gtk_window_set_decorated(GTK_WINDOW(window), false);
    GdkScreen* screen = gdk_screen_get_default();
        
    gtk_widget_set_colormap(window,
            gdk_screen_get_rgba_colormap(screen));

    gtk_window_maximize(GTK_WINDOW(window));
    gtk_window_set_keep_above(GTK_WINDOW(window), TRUE);
    return window;
}

GdkRectangle toolbar_rect = {0, 0, 1280, 42};
GdkRectangle bottom_rect = {0, 800-42-30, 1280, 30};

static void _show_region(
        int x, int y, int width, int height)
{
    GdkWindow* w = gtk_widget_get_window(window);
    
    GdkRectangle rect = {x, y, width, height};
    GdkRegion* region = gdk_region_rectangle(&toolbar_rect);
    gdk_region_union_with_rect(region, &rect);
    gdk_region_union_with_rect(region, &bottom_rect);


    gdk_window_shape_combine_region(w, region, 0, 0);
}

void xcb_init()
{
    connection = xcb_connect(NULL, NULL);
    xcb_screen_t* s = xcb_setup_roots_iterator(xcb_get_setup(connection)).data;
    uint32_t mask = XCB_CW_BACK_PIXEL | XCB_CW_EVENT_MASK;
    uint32_t values[2] = { s->white_pixel, XCB_EVENT_MASK_EXPOSURE | XCB_EVENT_MASK_KEY_PRESS };
    traywin = xcb_generate_id(connection);
    GdkWindow *wb = NULL;
    wb = gtk_widget_get_window(GTK_WIDGET(web_view));
    xcb_create_window(connection, XCB_COPY_FROM_PARENT, traywin, 
            GDK_WINDOW_XWINDOW(wb),
            100 , 0, 100, 100, 1,
            XCB_WINDOW_CLASS_INPUT_OUTPUT,
            s->root_visual, mask, values);
    xcb_map_window(connection, traywin);
    xcb_flush(connection);
}


int main(int argc, char* argv[])
{
    gtk_init(&argc, &argv);
    if (!g_thread_supported())
        g_thread_init(NULL);

    GtkWidget* vbox = gtk_vbox_new(FALSE, 0);
    gtk_box_pack_start(GTK_BOX(vbox), create_browser(), TRUE, TRUE, 0);
    main_window = create_window();
    gtk_container_add(GTK_CONTAINER(main_window), vbox);

    gchar* uri = (gchar*) "file:///home/snyh/src/deepin-desktop/taskbar.html";
    /*gchar* uri = (gchar*) "http://osjs.0o.no/";*/
    webkit_web_view_open(web_view, uri);

    gtk_widget_grab_focus(GTK_WIDGET(web_view));
    gtk_widget_show_all(main_window);
    xcb_init();
    gtk_main();
    return 0;
}
