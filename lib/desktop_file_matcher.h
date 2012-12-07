#ifndef _DESKTOP_FILE_MATCHER__
#define _DESKTOP_FILE_MATCHER__
#include <glib.h>
char* get_desktop_file_name_by_pid(int pid); /* the name is the basename of path without .desktop suffix and directory path*/
gboolean is_app_in_white_list(const char* name);

#endif
