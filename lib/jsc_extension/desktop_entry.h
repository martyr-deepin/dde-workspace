#ifndef __DESKTOP_ENTRY_H__
#define __DESKTOP_ENTRY_H__
#include <glib.h>

char* parse_desktop_item(const char* path);

char* get_desktop_entries();

char* move_to_desktop(const char* path);


char* get_desktop_dir(gboolean update);

char* get_icon_by_name(const char** name, int size);

#endif
