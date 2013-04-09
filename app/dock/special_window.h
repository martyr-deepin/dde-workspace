#ifndef _SPECIAL_WINDOW_
#define _SPECIAL_WINDOW_

#include "X_misc.h"

typedef enum _DesktopFocusState DesktopFocusState;
enum _DesktopFocusState {
    DESKTOP_HAS_FOCUS,
    DESKTOP_LOST_FOCUS,
    DESKTOP_FOCUS_UNKNOWN
};

extern Window launcher_id;
extern Window desktop_pid;

gboolean launcher_should_exit();
void close_launcher_window();
DesktopFocusState get_desktop_focus_state(Display* dsp);
void start_monitor_launcher_window(Display* dsp, Window w);
gboolean get_net_wm_pid(Display* dsp, Window id, gulong* net_wm_pid);

#endif
