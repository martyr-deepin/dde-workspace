

#ifndef _FILEOPS_ERROR_DIALOG_H_
#define _FILEOPS_ERROR_DIALOG_H_

#include <gtk/gtk.h>
#include "enums.h"

//#define 

//FileOpsResponse fileops_error_show_dialog (GError* error);
FileOpsResponse fileops_delete_trash_error_show_dialog (const char* fileops_str, GError* error, 
							GFile* file, GtkWindow* parent);
FileOpsResponse fileops_move_copy_error_show_dialog (const char* fileops_str, GError* error, 
	                                             GFile* src, GFile* dest, GtkWindow* parent);

#endif
