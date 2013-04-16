#ifndef __DOCK_HIDE_H__
#define __DOCK_HIDE_H__

#include <glib.h>
void dock_delay_show(int delay);
void dock_delay_hide(int delay);
void dock_show_now();
void dock_hide_now();
void dock_hide_real_now();
void dock_show_real_now();

void dock_toggle_show();
void dock_update_hide_mode();

void update_dock_guard_window_position();

void init_dock_guard_window();
gboolean is_mouse_in_dock();
#endif
