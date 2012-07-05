#include "taskbar.h"
#include "tray_manager.h"

struct _DTaskbarPrivate {
    GtkWidget *webview;
    GtkWidget *traybox;
    GdkScreen *screen;
    TrayManager *manager;
    guint idle_redraw_id;
    GtkOrientation orientation;
    GHashTable *icons;
};

G_DEFINE_TYPE(DTaskbar, d_taskbar, GTK_TYPE_CONTAINER);

void d1o_size_allocate(GtkWidget *w, GdkRectangle *allocation, gpointer user_data)
{
    /*GHashTableIter iter;
    gpointer key, value;
    g_hash_table_iter_init(&iter, icons);
    int count = g_hash_table_size(icons);
    for (int i=0; i<count; i++) {

        GtkAllocation allocation1 = {60 * i, 0, 50, 50};
        //printf("size_allocate icon:%d , %p\n", i, icons[i]);
        g_hash_table_iter_next(&iter, &key, &value);
        gtk_widget_set_size_request(GTK_WIDGET(key), 40, 40);
        //gtk_widget_size_allocate(GTK_WIDGET(key), &allocation1);
        gtk_widget_show_all(GTK_WIDGET(key));
    }*/
}

void tray_added(TrayManager *manager, GtkWidget* icon, gpointer data)
{
    if (gtk_widget_get_realized (GTK_WIDGET (icon)))
        gdk_window_set_composited (gtk_widget_get_window (GTK_WIDGET (icon)), FALSE);
    DTaskbar *taskbar= D_TASKBAR(GTK_WIDGET(data));
    DTaskbarPrivate *priv = taskbar->priv;

    gtk_box_pack_end(GTK_BOX(priv->traybox), icon, FALSE, FALSE, 0);

    gtk_widget_show(icon);

    //g_hash_table_insert(icons, icon, TRUE);
    printf("tray add:%p\n", icon, 0);
}

void tray_removed(TrayManager *manager, GtkWidget* icon, gpointer data)
{
    //g_hash_table_remove(icons, icon);
    printf("tray remove:%p\n", icon);
}

static void 
d_taskbar_size_request(GtkWidget *widget, GtkRequisition *requisition)
{
    DTaskbarPrivate *priv = D_TASKBAR(widget)->priv;

    gtk_widget_size_request(priv->webview, requisition);
}

static void
d_taskbar_size_allocate(GtkWidget *widget, GtkAllocation *allocation)
{
    DTaskbarPrivate *priv = D_TASKBAR(widget)->priv;
    gtk_widget_size_allocate(priv->webview, allocation);

    allocation->x = 800;
    allocation->y = 0;
    allocation->width = 300;
    allocation->height = 40;
    gtk_widget_size_allocate(priv->traybox, allocation);
}

static void
d_taskbar_init(DTaskbar *taskbar)
{
    DTaskbarPrivate *priv;
    priv = taskbar->priv = G_TYPE_INSTANCE_GET_PRIVATE(taskbar, D_TASKBAR_TYPE, DTaskbarPrivate);

    gtk_widget_set_has_window(GTK_WIDGET(taskbar), FALSE);

    priv->icons = g_hash_table_new(NULL, NULL);

    GdkDisplay *display = gdk_display_get_default();
    priv->screen = gdk_display_get_screen(display, 0);
    priv->manager = tray_manager_new();

    tray_manager_manage_screen(priv->manager, priv->screen);

    priv->traybox = gtk_hbox_new(TRUE, 0);
    gtk_widget_set_parent(priv->traybox, GTK_WIDGET(taskbar));
    gtk_widget_show(priv->traybox);

    priv->webview = d_webview_new();
    gtk_widget_set_parent(priv->webview, GTK_WIDGET(taskbar));

    gchar* uri = (gchar*) "file:///home/snyh/src/deepin-desktop/taskbar.html";
    webkit_web_view_open(WEBKIT_WEB_VIEW(priv->webview), uri);
    gtk_widget_show(priv->webview);
}

static void
d_taskbar_forall(GtkContainer *container, gboolean include_internals,
        GtkCallback callback, gpointer callback_data)
{
    DTaskbarPrivate *priv = D_TASKBAR(container)->priv;
    if (priv->webview) {
        (*callback)(priv->webview, callback_data);
    }
    if (priv->traybox) {
        (*callback)(priv->traybox, callback_data);
    }
}

static GType
d_taskbar_child_type(GtkContainer *container)
{
    return GTK_TYPE_WIDGET;
}
void d_taskbar_realize(GtkWidget *widget)
{
    GdkWindow *parent_window;
    GdkWindowAttr attributes;
    gint attributes_mask;
    gtk_widget_set_realized(widget, TRUE);

}


static void
d_taskbar_class_init(DTaskbarClass *klass)
{
    GObjectClass *gobject_class = G_OBJECT_CLASS(klass);
    GtkWidgetClass *widget_class = GTK_WIDGET_CLASS(klass);
    GtkContainerClass *container_class = GTK_CONTAINER_CLASS(klass);

    //widget_class->size_request = d_taskbar_size_request;
    widget_class->size_allocate = d_taskbar_size_allocate;
    //widget_class->realize = d_taskbar_realize;
    
    container_class->forall = d_taskbar_forall;
    container_class->child_type = d_taskbar_child_type;


    g_type_class_add_private(gobject_class, sizeof(DTaskbarPrivate));
}


GtkWidget* d_taskbar_new()
{
    GtkWidget* taskbar = g_object_new(D_TASKBAR_TYPE, NULL);
    DTaskbarPrivate *priv = D_TASKBAR(taskbar)->priv;

    g_signal_connect (priv->manager, "tray_icon_added", G_CALLBACK (tray_added), taskbar);
    g_signal_connect (priv->manager, "tray_icon_removed", G_CALLBACK (tray_removed), NULL);
    //g_signal_connect(taskbar, "size-allocate", G_CALLBACK(d1o_size_allocate), NULL);
    return taskbar;
}
