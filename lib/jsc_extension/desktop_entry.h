#ifndef __DESKTOP_ENTRY_H__
#define __DESKTOP_ENTRY_H__
#include <glib.h>

char* parse_desktop_entry(const char* path);
char* get_desktop_entries();
char* parse_normal_file(const char* path, gboolean is_dir);


char* get_icon_by_name(const char** name, int size);

char* lookup_icon(const char* theme, const char* type, const char* name, const int size);

#endif
