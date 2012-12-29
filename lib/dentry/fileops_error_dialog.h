// most of the code are copied from FileOps
#include <glib-object.h>
#include <gio/gio.h>
#include <gtk/gtk.h>

#include "xdg_misc.h"	// use char* lookup_icon_by_gicon(GIcon* icon);

#if 0
#define FILEOPS_TYPE_FILE_CONFLICT_DIALOG	(fileops_file_conflict_dialog_get_type ())
#define FILEOPS_FILE_CONFLICT_DIALOG(o)		(G_TYPE_CHECK_INSTANCE_CAST ((o),	\
						 FILEOPS_TYPE_FILE_CONFLICT_DIALOG,	\
						 FileOpsFileConflictDialog))
#define FILEOPS_FILE_CONFLICT_DIALOG_CLASS(k)	(G_TYPE_CHECK_CLASS_CAST ((k),		\
						 FILEOPS_TYPE_FILE_CONFLICT_DIALOG,	\
						 FileOpsFileConflictDialogClass))
#define FILEOPS_IS_FILE_CONFLICT_DIALOG(o)	(G_TYPE_CHECK_INSTANCE_TYPE ((o),	\
						 FILEOPS_TYPE_FILE_CONFLICT_DIALOG))
#define FILEOPS_IS_FILE_CONFLICT_DIALOG_CLASS(k) (G_TYPE_CHECK_CLASS_TYPE ((k),		\
						 FILEOPS_TYPE_FILE_CONFLICT_DIALOG))
#define FILEOPS_FILE_CONFLICT_DIALOG_GET_CLASS(o) (G_TYPE_INSTANCE_GET_CLASS ((o),	\
						  FILEOPS_TYPE_FILE_CONFLICT_DIALOG,	\
						  FileOpsFileConflictDialogClass))

typedef struct _FileOpsFileConflictDialog        FileOpsFileConflictDialog;
typedef struct _FileOpsFileConflictDialogClass   FileOpsFileConflictDialogClass;
typedef struct _FileOpsFileConflictDialogDetails FileOpsFileConflictDialogDetails;

struct _FileOpsFileConflictDialog {
	GtkDialog parent;
	FileOpsFileConflictDialogDetails *details;
};

struct _FileOpsFileConflictDialogClass {
	GtkDialogClass parent_class;
};

enum
{
	CONFLICT_RESPONSE_SKIP = 1,
	CONFLICT_RESPONSE_REPLACE = 2,
	CONFLICT_RESPONSE_RENAME = 3,
};

GType fileops_file_conflict_dialog_get_type (void) G_GNUC_CONST;
// use NULL for @parent 
GtkWidget* fileops_file_conflict_dialog_new (GtkWindow *parent, GFile *source, 
					     GFile *destination, GFile *dest_dir);
char*      fileops_file_conflict_dialog_get_new_name     (FileOpsFileConflictDialog *dialog);
gboolean   fileops_file_conflict_dialog_get_apply_to_all (FileOpsFileConflictDialog *dialog);
#endif

enum
{
	CONFLICT_RESPONSE_SKIP = 1,
	CONFLICT_RESPONSE_REPLACE = 2,
	CONFLICT_RESPONSE_RENAME = 3,
};

typedef struct _FileOpsFileConflictDialogDetails FileOpsFileConflictDialogDetails;

GtkDialog* fileops_error_conflict_dialog_new (GtkWindow* parent, GFile* src, GFile* dest);
