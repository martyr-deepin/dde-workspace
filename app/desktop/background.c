#include "X_misc.h"
#include <gdk/gdkx.h>
#include <gtk/gtk.h>
#include <cairo/cairo-xlib.h>

#include "background_util.h"

static GdkWindow* _background_window = NULL;

void setup_background_window()
{
    GdkWindowAttr attributes;
    attributes.width = 0;
    attributes.height = 0;
    attributes.window_type = GDK_WINDOW_CHILD;
    attributes.wclass = GDK_INPUT_OUTPUT;
    attributes.event_mask = GDK_EXPOSURE_MASK;

    _background_window = gdk_window_new(NULL, &attributes, 0);
    set_wmspec_desktop_hint(_background_window);

    gdk_window_move_resize(_background_window, 0, 0,
                           gdk_window_get_width(root),
                           gdk_window_get_height(root));

    bg_util_init (_background_window);
    bg_util_connect_screen_signals (_background_window);

    //gdk_window_show(_background_window);
    gdk_window_show_unraised(_background_window);
}
