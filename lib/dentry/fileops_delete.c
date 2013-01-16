#include <gtk/gtk.h>
#include <glib/gi18n.h>

#include "fileops.h"
#include "fileops_delete.h"

void fileops_confirm_delete (GFile* file_list[], guint num, gboolean show_dialog)
{
    GtkWidget* dialog;
    int result = GTK_RESPONSE_OK;

    if (show_dialog)
    {
	dialog = gtk_message_dialog_new (NULL, 
					 GTK_DIALOG_MODAL,
					 GTK_MESSAGE_WARNING, 
					 GTK_BUTTONS_CANCEL,
					 NULL);
	gtk_window_set_title (GTK_WINDOW (dialog), _("Delete File"));
	gtk_window_set_modal (GTK_WINDOW (dialog), TRUE);
	g_object_set (dialog,
	          "text", _("Are you sure you want to permanently delete the files?"),
		  "secondary-text", _("If you delete an item, it will be permanently lost"),
		  NULL);

	gtk_dialog_add_buttons (GTK_DIALOG (dialog), _("Delete"), 
				GTK_RESPONSE_OK, NULL);

	result = gtk_dialog_run (GTK_DIALOG (dialog));
	gtk_widget_destroy (dialog);
    }

    if (result == GTK_RESPONSE_OK)
         fileops_delete (file_list, num);
}
