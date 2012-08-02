#include "forward_window.h"
#include <gdk/gdk.h>
#include <gdk/gdkx.h>

void print_event(GdkEvent* event)
{
    switch (event->type) {
        case GDK_EXPOSE:
            puts("GDK_EXPOSE\n");
            break;
        case GDK_BUTTON_PRESS:
            puts("GDK_BUTTON_PRESS\n");
            break;
        case GDK_MOTION_NOTIFY:
            puts("GDK_MOTION_NOTIFY\n");
            break;
        case GDK_ENTER_NOTIFY:
            puts("GDK_ENTER_NOTIFY\n");
            break;
        case GDK_LEAVE_NOTIFY:
            puts("GDK_LEAVE_NOTIFY\n");
            break;
        case GDK_FOCUS_CHANGE:
            puts("GDK_FOCUS_CHANGE\n");
            break;
        case GDK_BUTTON_RELEASE:
            puts("GDK_BUTTON_RELEASE\n");
            break;

    }
    GdkEventAny* any = (GdkEventAny*)event;
    /*printf("window:%p\n", any->window);*/
}

G_DEFINE_TYPE (DForwardWindow, d_forward_window, GTK_TYPE_INVISIBLE)

#define GET_PRIVATE(obj) G_TYPE_INSTANCE_GET_PRIVATE(obj, D_TYPE_FORWARD_WINDOW, DForwardWindowPrivate)

typedef struct _DForwardWindowPrivate DForwardWindowPrivate;

struct _DForwardWindowPrivate {
    GdkWindow *origin_window;
    int x;
    int y;
    int width;
    int height;
};

void d_forward_window_set_show_region(GtkWidget* widget, int x, int y, int width, int height)
{
    if (gtk_widget_get_realized(widget)) {
        GdkWindow* window = gtk_widget_get_window(widget);
        cairo_rectangle_int_t rect = {x, y, width, height};
        cairo_region_t *region = cairo_region_create_rectangle(&rect);
        gdk_window_shape_combine_region(window, region , 0, 0);
    }
}

void d_forward_window_set_position(GtkWidget *widget, int x, int y, 
        int width, int height)
{
    DForwardWindowPrivate *priv = GET_PRIVATE(widget);
    priv->x = x;
    priv->y = y;
    priv->width = width;
    priv->height = height;
}

static void
d_forward_window_send_configure (GtkWidget *widget)
{
  GtkAllocation allocation;
  GdkEvent *event = gdk_event_new (GDK_CONFIGURE);

  gtk_widget_get_allocation (widget, &allocation);

  event->configure.window = g_object_ref (gtk_widget_get_window (widget));
  event->configure.send_event = TRUE;
  event->configure.x = allocation.x;
  event->configure.y = allocation.y;
  event->configure.width = allocation.width;
  event->configure.height = allocation.height;

  gtk_widget_event (widget, event);
  gdk_event_free (event);
}

static void
d_forward_window_realize(GtkWidget *widget)
{
    GdkWindow *parent;
    GdkWindow *window;
    GdkWindowAttr attributes;
    gint attributes_mask;

    gtk_widget_set_realized (widget, TRUE);

    parent = gtk_widget_get_parent_window (widget);
    if (parent == NULL)
        parent = gtk_widget_get_root_window (widget);

    attributes.x = 0;
    attributes.y = 0;
    attributes.width = 0;
    attributes.height = 0;
    attributes.window_type = GDK_WINDOW_TEMP;
    attributes.wclass = GDK_INPUT_OUTPUT;
    /*attributes.override_redirect = TRUE;*/
    attributes.event_mask = GDK_ALL_EVENTS_MASK;
    attributes.visual = gdk_screen_get_rgba_visual(gdk_screen_get_default());
    attributes.type_hint = GDK_WINDOW_TYPE_HINT_POPUP_MENU;

    attributes_mask = GDK_WA_X | GDK_WA_Y | GDK_WA_VISUAL;

    window = gdk_window_new (parent, &attributes, attributes_mask);

    gtk_widget_set_window (widget, window);
    gdk_window_set_user_data (window, widget);

    d_forward_window_send_configure(widget);
}

static gboolean
d_forward_window_draw(GtkWidget* fw, cairo_t *cr)
{
    return TRUE;
}

static void
d_forward_window_size_allocate (GtkWidget     *widget,
        GtkAllocation *allocation)
{
    gtk_widget_set_allocation (widget, allocation);
    if (gtk_widget_get_realized(widget)) {
        gdk_window_move_resize(gtk_widget_get_window(widget),
                allocation->x, allocation->y, allocation->width, allocation->height);
        d_forward_window_send_configure(widget);
    }
}

    static void
d_forward_window_class_init (DForwardWindowClass *class)
{
    GObjectClass *gobject_class = (GObjectClass*)class;
    GtkWidgetClass *widget_class = (GtkWidgetClass*)class;

    widget_class->realize = d_forward_window_realize;
    /*widget_class->draw = d_forward_window_draw;*/
    /*widget_class->size_allocate = d_forward_window_size_allocate;*/

    g_type_class_add_private(gobject_class, sizeof(DForwardWindowPrivate));

}

gint64 timestamp = 0;
static gboolean
d_forward_window_do_forward(GtkWidget *widget, GdkEvent* event, gpointer data)
{
    switch (event->type) {
        case GDK_MOTION_NOTIFY:
        case GDK_BUTTON_PRESS:
        case GDK_2BUTTON_PRESS:
        case GDK_3BUTTON_PRESS:
        case GDK_BUTTON_RELEASE:
        case GDK_KEY_PRESS:
        case GDK_KEY_RELEASE:
            break;
        default:
            return TRUE;

    }

    /*printf("%d\n", g_get_monotonic_time() - timestamp);*/
    /*if (g_get_monotonic_time() - timestamp < 20000) {*/
        /*puts("nnnn\n");*/
        /*return FALSE;*/
    /*}*/
    /*timestamp = g_get_monotonic_time();*/

    DForwardWindowPrivate *priv = GET_PRIVATE(widget);
    GdkEventAny *any = (GdkEventAny*)event;
    any->send_event = FALSE;
    any->window = g_object_ref(priv->origin_window);

    GdkEventMotion *e_b = (GdkEventMotion*)event;

    e_b->x = e_b->x_root;
    e_b->y = e_b->y_root - 27;

    gtk_main_do_event(event);

    return TRUE;
}

static void
d_forward_window_init (DForwardWindow* fw)
{
    gtk_widget_set_has_window (GTK_WIDGET (fw), TRUE);
    gtk_widget_set_app_paintable (GTK_WIDGET(fw), TRUE);
}

GtkWidget*
d_forward_window_new(GdkWindow* origin_window)
{

    GtkWidget* fw = g_object_new(D_TYPE_FORWARD_WINDOW, NULL);
    GET_PRIVATE(fw)->origin_window = origin_window;
    g_signal_connect(GTK_WIDGET(fw), "event", G_CALLBACK(d_forward_window_do_forward), NULL);
    return fw;
}


gboolean d_forward_window_need_change(GtkWidget *widget, 
        int x, int y, int width, int height)
{
    DForwardWindowPrivate *priv = GET_PRIVATE(widget);
    if (priv->x != x || priv->y != y || 
            priv->width != width || priv->height != height)
        return TRUE;
    else
        return FALSE;
}
void d_forward_window_move(GtkWidget* widget,
        int x, int y, int width, int height)
{
    if (width == -1 && height == -1)
        XMoveWindow(gdk_x11_get_default_xdisplay(),
                GDK_WINDOW_XID(gtk_widget_get_window(widget)),
                x, y);
}
