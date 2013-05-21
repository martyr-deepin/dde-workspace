#include "dock_test.h"


void dock_test_special_window()
{
    Display *_dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    extern DesktopFocusState get_desktop_focus_state(Display* dsp);
    Test({
         get_desktop_focus_state(_dsp);
         }, "get_desktop_focus_state");
}
