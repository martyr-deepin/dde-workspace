
#ifndef _FILEOPS_CONFIRM_TRASH_H_
#define _FILEOPS_CONFIRM_TRASH_H_

#include <gtk/gtk.h>

int fileops_confirm_trash (GtkWindow* window);

void fileops_empty_trash ();

GFile* fileops_get_trash_entry();
double fileops_get_trash_count();
#endif
