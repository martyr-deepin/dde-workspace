#include "dock.h"
#include "jsextension.h"
#include <gdk/gdkx.h>


gboolean do_fix()
{
    static GRWLock lock;
    g_rw_lock_writer_lock(&lock);
    update_primary_info(&dock);
    g_rw_lock_writer_unlock(&lock);

    static int count = 0;
    count++;

    GdkWindow* w = DOCK_GDK_WINDOW();

    GdkGeometry geo = {0};
    geo.min_width = 0;
    geo.min_height = 0;
    gdk_window_set_geometry_hints(w, &geo, GDK_HINT_MIN_SIZE);

    XSelectInput(gdk_x11_get_default_xdisplay(), GDK_WINDOW_XID(w), NoEventMask);

    gdk_window_move_resize(w, dock.x, dock.y, dock.width, dock.height);

    gdk_flush();

    gdk_window_set_events(w, gdk_window_get_events(w));

    if (count == 5) {
        count = 0;
        return G_SOURCE_REMOVE;
    }
    return G_SOURCE_CONTINUE;
}


JS_EXPORT_API
void dock_fix_switch()
{
    do_fix();
    g_timeout_add_seconds(1, do_fix, NULL);
}

