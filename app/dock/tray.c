#include "notification_area/na-tray-manager.h"
#include "X_misc.h"

#define DEFAULT_WIDTH 24
#define DEFAULT_INTERVAL 30
GHashTable* icons = NULL;

void tray_icon_added (NaTrayManager *manager, Window child, GtkWidget* container)
{
    GdkWindow* icon = gdk_x11_window_foreign_new_for_display(gdk_display_get_default(), child);

    printf("add icon %p\n", icon);
    gint x = g_hash_table_size(icons) * DEFAULT_INTERVAL;
    gint y = 0;

    gint xy = y + (x  << 16);
    g_hash_table_insert(icons, icon, GINT_TO_POINTER(xy)); 

    gdk_window_reparent(icon, gtk_widget_get_window(container), x, y);
    gdk_window_set_events(icon, GDK_VISIBILITY_NOTIFY_MASK); //add this mask so, gdk can handle GDK_SELECTION_CLEAR event to destroy this gdkwindow.
    gdk_window_set_composited(icon, TRUE);

    gdk_window_resize(icon, DEFAULT_WIDTH, DEFAULT_WIDTH);

    char* msg = g_strdup_printf("{\"id\":%d}", GPOINTER_TO_INT(icon));
    js_post_message("tray_icon_add", msg);
    g_free(msg);

    gdk_window_show(icon);

}

GSList* tmp_remove = NULL;
void draw_tray_icon(GdkWindow* icon, gint xy, cairo_t* cr)
{
    if (gdk_window_is_destroyed(icon)) {
        tmp_remove = g_slist_append(tmp_remove, icon);
    } else {
        gint x = xy >> 16;
        gint y = xy & 0xffff;
        gdk_cairo_set_source_window(cr, icon, x, y);
        cairo_paint(cr);
    }
}

void remove_destroyed_icon(GdkWindow* icon)
{
    printf("remove destroyed icon %p\n", icon);
    g_hash_table_remove(icons, icon);
}

gboolean draw_icons(GtkWidget* w, cairo_t *cr, gpointer data)
{
    g_hash_table_foreach(icons, (GHFunc)draw_tray_icon, cr);
    g_slist_free_full(tmp_remove, (GDestroyNotify)remove_destroyed_icon);
    tmp_remove = NULL;
    return TRUE;
}


void set_notifyarea_allocation(double x, double y, double width, double height)
{
}


void set_tray_icon_position(double _icon, double _x, double _y)
{
    GdkWindow* icon = (GdkWindow*)GINT_TO_POINTER((gint)_icon);
    int x = (int) _x;
    int y = (int) _y;
}

void tray_init(GtkWidget* container)
{
    GdkScreen* screen = gdk_screen_get_default();
    NaTrayManager* tray_manager = NULL;
    tray_manager = na_tray_manager_new();
    na_tray_manager_manage_screen(tray_manager, screen);

    icons = g_hash_table_new(g_direct_hash, g_direct_equal);

    g_signal_connect(tray_manager, "tray_icon_added", G_CALLBACK(tray_icon_added), container);
}
