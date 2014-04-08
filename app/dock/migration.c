#include "X_misc.h"
#include "pixbuf.h"
#include "utils.h"
#include "xid2aid.h"
#include "launcher.h"
#include "dock_config.h"
#include "dominant_color.h"
#include "handle_icon.h"
#include "tasklist.h"
#include "dock_hide.h"
#include "region.h"
#include "special_window.h"
#include "xdg_misc.h"
int _is_maximized_window(Window win)
{
    gulong items;
    Atom ATOM_WINDOW_NET_STATE = gdk_x11_get_xatom_by_name("_NET_WM_STATE");
    Atom ATOM_WINDOW_MAXIMIZED_VERT = gdk_x11_get_xatom_by_name("_NET_WM_STATE_MAXIMIZED_VERT");
    Display* _dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    long* data = get_window_property(_dsp, win, ATOM_WINDOW_NET_STATE, &items);

    if (data != NULL) {
        for (guint i=0; i<items; i++) {
            if ((Atom)X_FETCH_32(data, i) == ATOM_WINDOW_MAXIMIZED_VERT) {
                XFree(data);
                return 1;
            }
        }
        XFree(data);
    }
    return 0;
}
gboolean dock_has_maximize_client()
{
    Atom ATOM_CLIENT_LIST = gdk_x11_get_xatom_by_name("_NET_CLIENT_LIST");
    Display* _dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    gulong items;
    Window root = GDK_ROOT_WINDOW();
    void* data = get_window_property(_dsp, root, ATOM_CLIENT_LIST, &items);

    gboolean has = FALSE;

    if (data == NULL) return has;

    for (guint i=0; i<items; i++) {
        Window xid = X_FETCH_32(data, i);
        if (_is_maximized_window(xid)) {
            has = TRUE;
            goto out;
        }
    }

out:
    XFree(data);

    return has;
}
int dock_has_overlay_client()
{
    return 0;
}
void active_window_changed() {
}
int dock_is_client_minimized(double xid)
{
}

gboolean is_has_client(const char* app_id) {
    return 0;
}

