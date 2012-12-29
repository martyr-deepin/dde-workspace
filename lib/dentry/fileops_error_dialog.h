// most of the code are copied from FileOps
#include <glib-object.h>
#include <gio/gio.h>
#include <gtk/gtk.h>

#include "enums.h"
#include "xdg_misc.h"	// use char* lookup_icon_by_gicon(GIcon* icon);


typedef struct _FileOpsFileConflictDialogDetails FileOpsFileConflictDialogDetails;

GtkWidget* fileops_error_conflict_dialog_new (GtkWindow* parent, GFile* src, 
	                                      GFile* dest, char* file_name);
