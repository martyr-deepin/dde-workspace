#ifndef __DESKTOP_UTILS__
#define __DESKTOP_UTILS__

#include <gtk/gtk.h>
#include "dentry/entry.h"

void desktop_run_in_terminal(char* executable);
void desktop_run_terminal();

void desktop_run_deepin_settings(const char* mod);

void desktop_open_trash_can();

Entry* desktop_get_home_entry();

Entry* desktop_get_computer_entry();

char* desktop_get_transient_icon (Entry* p1);

gboolean force_get_input_focus(GtkWidget* widget);

#endif
