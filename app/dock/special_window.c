#include <gtk/gtk.h>
#include "jsextension.h"
#include "special_window.h"

extern Window active_client_id;
extern Window get_dock_window();
extern void dock_close_window(double id);

Window launcher_id = 0;
gulong desktop_pid = 0;

gboolean launcher_should_exit()
{
    return active_client_id != get_dock_window() && active_client_id != launcher_id;
}

void close_launcher_window()
{
    dock_close_window(launcher_id);
}

static
gboolean desktop_has_focus(Display* dsp, gboolean* ret)
{
    gboolean state;
    gulong active_client_wm_pid;
    if (state = get_net_wm_pid(dsp, active_client_id, &active_client_wm_pid)) {
        *ret = active_client_wm_pid == desktop_pid;
    }

    return state;
}

DesktopFocusState get_desktop_focus_state(Display* dsp)
{
    gboolean is_focus;
    if (desktop_has_focus(dsp, &is_focus))
        return is_focus ? DESKTOP_HAS_FOCUS : DESKTOP_LOST_FOCUS;
    else
        return DESKTOP_FOCUS_UNKNOWN;
}

static
GdkFilterReturn _monitor_launcher_window(GdkXEvent* xevent, GdkEvent* event, Window win)
{
    XEvent* xev = xevent;
    if (xev->type == DestroyNotify) {
        js_post_message_simply("launcher_destroy", NULL);
        launcher_id = 0;
    }
    return GDK_FILTER_CONTINUE;
}

void start_monitor_launcher_window(Display* dsp, Window w)
{
    launcher_id = w;
    GdkWindow* win = gdk_x11_window_foreign_new_for_display(gdk_x11_lookup_xdisplay(dsp), w);
    if (win == NULL)
        return;
    js_post_message_simply("launcher_running", NULL);

    g_assert(win != NULL);
    gdk_window_set_events(win, GDK_VISIBILITY_NOTIFY_MASK | gdk_window_get_events(win));
    gdk_window_add_filter(win, (GdkFilterFunc)_monitor_launcher_window, GINT_TO_POINTER(w));
}

gboolean get_net_wm_pid(Display* dsp, Window id, gulong* net_wm_pid)
{
    Atom atom_net_wm_pid = gdk_x11_get_xatom_by_name("_NET_WM_PID");
    gulong n_item;
    gpointer data = get_window_property(dsp, id, atom_net_wm_pid, &n_item);
    if (data != NULL) {
        *net_wm_pid = X_FETCH_32(data, 0);
        XFree(data);
        return TRUE;
    }
    return FALSE;
}
