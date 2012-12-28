#include <time.h>
#include <string.h>
#include <string.h>

#include <glib-object.h>
#include <gio/gio.h>
#include <glib/gi18n.h>
#include <pango/pango.h>
#include <gtk/gtk.h>

#include "fileops_error_dialog.h"

struct _FileOpsFileConflictDialogDetails
{
	/* conflicting objects */
	GFile *source;
	GFile *destination;
	GFile *dest_dir;

	gchar *conflict_name;
	//NautilusFileListHandle *handle;
	//gulong src_handler_id;
	//gulong dest_handler_id;

	/* UI objects */
	GtkWidget *titles_vbox;
	GtkWidget *first_hbox;
	GtkWidget *second_hbox;
	GtkWidget *expander;
	GtkWidget *entry;
	GtkWidget *checkbox;
	GtkWidget *rename_button;
	GtkWidget *replace_button;
	GtkWidget *dest_image;
	GtkWidget *src_image;
};

static void _expander_activated_cb (GtkExpander *w, GtkDialog *dialog);
static void _entry_text_changed_cb (GtkEditable *entry, GtkDialog *dialog);
static void _reset_button_clicked_cb (GtkButton *w, GtkDialog *dialog);
static void _checkbox_toggled_cb (GtkToggleButton *t, GtkDialog *dialog);

static void _setup_dialog_labels (GFile* src, GFile* dest, GtkDialog* dialog);
static void _file_icons_changed (GFile *file, GtkDialog *dialog);
//eel stuff
static char * eel_filename_strip_extension (const char * filename_with_extension);
static void eel_filename_get_rename_region (const char *filename, int *start_offset, int *end_offset);
static char * eel_filename_get_extension_offset (const char *filename);

static FileOpsFileConflictDialogDetails details;
static GtkDialog *dialog;

void show_conflict_dialog (GtkWindow* parent, GFile* src, GFile* dest)
{
    g_debug ("show_conflict_dialog");
    //details from parameters
    GtkWidget *hbox, *vbox, *vbox2, *alignment;
    GtkWidget *widget, *dialog_area;

    dialog = GTK_DIALOG (gtk_dialog_new ());
    gtk_window_set_transient_for (GTK_WINDOW (dialog), parent);

    /* Setup the main hbox */
    hbox = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 12);
    dialog_area = gtk_dialog_get_content_area (dialog);
    gtk_box_pack_start (GTK_BOX (dialog_area), hbox, FALSE, FALSE, 0);
    gtk_container_set_border_width (GTK_CONTAINER (hbox), 6);

    /* Setup the dialog image */
    widget = gtk_image_new_from_stock (GTK_STOCK_DIALOG_WARNING,
				       GTK_ICON_SIZE_DIALOG);
    gtk_box_pack_start (GTK_BOX (hbox), widget, FALSE, FALSE, 0);
    gtk_misc_set_alignment (GTK_MISC (widget), 0.5, 0.0);

    /* Setup the vbox containing the dialog body */
    vbox = gtk_box_new (GTK_ORIENTATION_VERTICAL, 12);
    gtk_box_pack_start (GTK_BOX (hbox), vbox, FALSE, FALSE, 0);

    /* Setup the vbox for the dialog labels */
    widget = gtk_box_new (GTK_ORIENTATION_VERTICAL, 12);
    gtk_box_pack_start (GTK_BOX (vbox), widget, FALSE, FALSE, 0);
	
    //1.
    details.titles_vbox = widget;

    /* Setup the hboxes to pack file infos into */
    alignment = gtk_alignment_new (0.0, 0.0, 0.0, 0.0);
    g_object_set (alignment, "left-padding", 12, NULL);
    vbox2 = gtk_box_new (GTK_ORIENTATION_VERTICAL, 12);
    gtk_container_add (GTK_CONTAINER (alignment), vbox2);
    gtk_box_pack_start (GTK_BOX (vbox), alignment, FALSE, FALSE, 0);

    //2.src
    hbox = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 12);
    gtk_box_pack_start (GTK_BOX (vbox2), hbox, FALSE, FALSE, 0);
    details.first_hbox = hbox;
    //3.dest
    hbox = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 12);
    gtk_box_pack_start (GTK_BOX (vbox2), hbox, FALSE, FALSE, 0);
    details.second_hbox = hbox;

    //4.expander.
    details.expander = gtk_expander_new_with_mnemonic (_("_Select a new name for the destination"));
    gtk_box_pack_start (GTK_BOX (vbox2), details.expander, FALSE, FALSE, 0);
    g_signal_connect (details.expander, "activate", G_CALLBACK (_expander_activated_cb), dialog);
    //5.expander entry
    hbox = gtk_box_new (GTK_ORIENTATION_HORIZONTAL, 6);
    gtk_container_add (GTK_CONTAINER (details.expander), hbox);
    widget = gtk_entry_new ();
    gtk_box_pack_start (GTK_BOX (hbox), widget, TRUE, TRUE, 6);
    g_signal_connect (widget, "changed", G_CALLBACK (_entry_text_changed_cb), dialog);
    details.entry = widget;
    //expander reset button
    widget = gtk_button_new_with_label (_("Reset"));
    gtk_button_set_image (GTK_BUTTON (widget),
			 gtk_image_new_from_stock (GTK_STOCK_UNDO, GTK_ICON_SIZE_MENU));
    gtk_box_pack_start (GTK_BOX (hbox), widget, FALSE, FALSE, 6);
    g_signal_connect (widget, "clicked", G_CALLBACK (_reset_button_clicked_cb), dialog);

    gtk_widget_show_all (alignment);

    //6. checkbox
    widget = gtk_check_button_new_with_mnemonic (_("Apply this action to all files"));
    gtk_box_pack_start (GTK_BOX (vbox), widget, FALSE, FALSE, 0);
    g_signal_connect (widget, "toggled", G_CALLBACK (_checkbox_toggled_cb), dialog);
    details.checkbox = widget;

    //buttons
    gtk_dialog_add_buttons (dialog, GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL,
			    _("_Skip"), CONFLICT_RESPONSE_SKIP,	NULL);

    //7. rename
    details.rename_button = gtk_dialog_add_button (dialog, _("Re_name"),
						    CONFLICT_RESPONSE_RENAME);
    gtk_widget_hide (details.rename_button);

    //8. replace
    details.replace_button = gtk_dialog_add_button (dialog, _("Replace"), 
						     CONFLICT_RESPONSE_REPLACE);
    
    gtk_widget_grab_focus (details.replace_button);

    /* Setup HIG properties */
    gtk_container_set_border_width (GTK_CONTAINER (dialog), 5);
    gtk_box_set_spacing (GTK_BOX (gtk_dialog_get_content_area (dialog)), 14);
    gtk_window_set_resizable (GTK_WINDOW (dialog), FALSE);

    gtk_widget_show_all (dialog_area);

    _setup_dialog_labels (src, dest, dialog); 

    gtk_widget_show (GTK_WIDGET (dialog));
}

static void
_setup_dialog_labels (GFile* src, GFile* dest, GtkDialog* dialog)
{
    //details.handle = NULL;
    g_debug ("__setup_dialog_labels");

    GFile* dest_dir = g_file_get_parent (dest);

    GFileInfo *src_info, *dest_info, *dest_dir_info;
    src_info = g_file_query_info (src, "standard::*,time::*",
				  G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS,
				  NULL, NULL);
    dest_info = g_file_query_info (dest, "standard::*,time::*",
				   G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS,
				   NULL, NULL);
    dest_dir_info = g_file_query_info (dest_dir, "standard::*,time::*",
				   G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS,
				   NULL, NULL);

    //clean up 
    time_t src_mtime, dest_mtime;
    GTimeVal src_gtime, dest_gtime;
    g_file_info_get_modification_time (src_info, &src_gtime);
    g_file_info_get_modification_time (dest_info, &dest_gtime);
    if (src_gtime.tv_sec)
	g_debug ("src: %li", src_gtime.tv_usec);
    if (dest_gtime.tv_sec)
	g_debug ("src: %li", dest_gtime.tv_usec);

    src_mtime = src_gtime.tv_sec;
    dest_mtime = dest_gtime.tv_sec;

    const char *dest_name, *dest_dir_name;
    dest_name = g_file_info_get_display_name (dest_info);
    dest_dir_name = g_file_info_get_display_name (dest_dir_info);

    gboolean source_is_dir, dest_is_dir;
    source_is_dir = g_file_info_get_file_type (src_info) ==
		    G_FILE_TYPE_DIRECTORY ? TRUE : FALSE;
    dest_is_dir = g_file_info_get_file_type (dest_info) ==
		    G_FILE_TYPE_DIRECTORY ? TRUE : FALSE;


    // message layout:
    // @primary_text
    // @secondary_text
    //		+ @message
    //		+ @message_extra
    char *primary_text, *secondary_text;
    char *message_extra, *message;
    if (dest_is_dir) 
    {
	if (source_is_dir) 
	{
	    primary_text = g_strdup_printf (_("Merge folder \"%s\"?"), 
		                            dest_name);
	    message_extra = _("Merging will ask for confirmation before "
		              "replacing any files in the folder that "
			      "conflict with the files being copied.");
	    if (src_mtime > dest_mtime) 
		message = g_strdup_printf (_("An older folder with the same "
			                   "name already exists in \"%s\"."), 
			                   dest_dir_name);
	    else if (src_mtime < dest_mtime) 
		message = g_strdup_printf (_("A newer folder with the same "
			                   "name already exists in \"%s\"."), 
					   dest_dir_name);
	    else 
		message = g_strdup_printf (_("Another folder with the same "
			                   "name already exists in \"%s\"."), 
			                   dest_dir_name);
	} 
	else 
	{
	    message_extra = _("Replacing it will remove all files in the"
		              "folder.");
	    primary_text = g_strdup_printf (_("Replace folder \"%s\"?"), 
		                            dest_name);
	    message = g_strdup_printf (_("A folder with the same name already " 
			               "exists in \"%s\"."), dest_dir_name);
	}
    } 
    else 
    {
	primary_text = g_strdup_printf (_("Replace file \"%s\"?"), dest_name);
	message_extra = _("Replacing it will overwrite its content.");
	if (src_mtime > dest_mtime) 
	    message = g_strdup_printf (_("An older file with the same name "
			               "already exists in \"%s\"."), 
		                       dest_dir_name);
       	else if (src_mtime < dest_mtime) 
	    message = g_strdup_printf (_("A newer file with the same name "
			               "already exists in \"%s\"."), 
		                       dest_dir_name);
	else 
	    message = g_strdup_printf (_("Another file with the same name "
			              "already exists in \"%s\"."), 
		                      dest_dir_name);
    }
    secondary_text = g_strdup_printf ("%s\n%s", message, message_extra);
    g_free (message);

    //1. setup primary text and secondary text;
    GtkWidget *label;
    
    label = gtk_label_new (primary_text);
    gtk_label_set_line_wrap (GTK_LABEL (label), TRUE);
    gtk_label_set_line_wrap_mode (GTK_LABEL (label), PANGO_WRAP_WORD_CHAR);
    gtk_misc_set_alignment (GTK_MISC (label), 0.0, 0.5);
    gtk_box_pack_start (GTK_BOX (details.titles_vbox), label, FALSE, FALSE, 0);
    gtk_widget_show (label);

    PangoAttrList *attr_list;
    attr_list = pango_attr_list_new ();
    pango_attr_list_insert (attr_list, pango_attr_weight_new (PANGO_WEIGHT_BOLD));
    pango_attr_list_insert (attr_list, pango_attr_scale_new (PANGO_SCALE_LARGE));
    g_object_set (label, "attributes", attr_list, NULL);
    pango_attr_list_unref (attr_list);

    label = gtk_label_new (secondary_text);
    gtk_label_set_line_wrap (GTK_LABEL (label), TRUE);
    gtk_misc_set_alignment (GTK_MISC (label), 0.0, 0.5);
    gtk_box_pack_start (GTK_BOX (details.titles_vbox), label, FALSE, FALSE, 0);
    gtk_widget_show (label);
    g_free (primary_text);
    g_free (secondary_text);

    //2. setup file icons;
    GIcon* icon;
    char* icon_name;

    icon = g_file_info_get_icon (dest_info);
    icon_name = lookup_icon_by_gicon (icon); //from xdg_misc.h
    details.dest_image = gtk_image_new_from_file (icon_name);
    gtk_box_pack_start (GTK_BOX (details.first_hbox), details.dest_image, FALSE, FALSE, 0);
    gtk_widget_show (details.dest_image);
    //g_free (icon);
    g_free (icon_name);

    icon = g_file_info_get_icon (src_info);
    icon_name = lookup_icon_by_gicon (icon); //from xdg_misc.h
    details.src_image = gtk_image_new_from_file (icon_name);
    gtk_box_pack_start (GTK_BOX (details.second_hbox), details.src_image, FALSE, FALSE, 0);
    gtk_widget_show (details.src_image);
    //g_free (icon);
    g_free (icon_name);

    //3. setup file info
    gboolean should_show_type;
    const char* src_type = g_file_info_get_content_type (src_info);
    const char* dest_type = g_file_info_get_content_type (dest_info);
    should_show_type = !g_content_type_is_a (src_type, dest_type);

    char* date = NULL;
    goffset size = 0;
    char* type = NULL;

    label = gtk_label_new (NULL);
    date = g_strdup (ctime (&dest_mtime));
    size = g_file_info_get_size (dest_info);

    if (should_show_type)
	type = g_strdup (dest_type);

    GString *str;
    str = g_string_new (NULL);
    g_string_append_printf (str, "<b>%s</b>\n", _("Original file"));
    g_string_append_printf (str, "<i>%s</i> %li Bytes\n", _("Size:"), size);

    if (should_show_type)
    {
	g_string_append_printf (str, "<i>%s</i> %s\n", _("Type:"), type);
	g_free (type);
    }

    g_string_append_printf (str, "<i>%s</i> %s", _("Last modified:"), date);

    char *label_text;
    label_text = str->str;
    gtk_label_set_markup (GTK_LABEL (label), label_text);
    gtk_box_pack_start (GTK_BOX (details.first_hbox), label, FALSE, FALSE, 0);
    gtk_widget_show (label);

    g_free (date);
    g_string_erase (str, 0, -1);

    /* Second label */
    label = gtk_label_new (NULL);
    date = g_strdup (ctime (&src_mtime));
    size = g_file_info_get_size (dest_info);

    if (should_show_type) 
	type = g_strdup (src_type);

    g_string_append_printf (str, "<b>%s</b>\n", _("Replace with"));
    g_string_append_printf (str, "<i>%s</i> %li Bytes\n", _("Size:"), size);

    if (should_show_type) 
    {
	g_string_append_printf (str, "<i>%s</i> %s\n", _("Type:"), type);
	g_free (type);
    }

    g_string_append_printf (str, "<i>%s</i> %s", _("Last modified:"), date);

    label_text = g_string_free (str, FALSE);
    gtk_label_set_markup (GTK_LABEL (label), label_text);
    gtk_box_pack_start (GTK_BOX (details.second_hbox), label, FALSE, FALSE, 0);
    gtk_widget_show (label);

    g_free (date);
    g_free (label_text);

    /* Populate the entry */
    const char* edit_name;
    edit_name = g_file_info_get_edit_name (dest_info);
    details.conflict_name = g_strdup (edit_name);
    gtk_entry_set_text (GTK_ENTRY (details.entry), edit_name);

    if (source_is_dir && dest_is_dir)
	gtk_button_set_label (GTK_BUTTON (details.replace_button), _("Merge"));
}
static void
_expander_activated_cb (GtkExpander *w, GtkDialog *dialog)
{
    int start_pos, end_pos;

    if (!gtk_expander_get_expanded (w)) 
    {
	if (g_strcmp0 (gtk_entry_get_text (GTK_ENTRY (details.entry)),
		       details.conflict_name) == 0) 
	{
	    gtk_widget_grab_focus (details.entry);

	    eel_filename_get_rename_region (details.conflict_name,
					    &start_pos, &end_pos);
	    gtk_editable_select_region (GTK_EDITABLE (details.entry),
					start_pos, end_pos);
	}
    }
}
static void
_entry_text_changed_cb (GtkEditable *entry, GtkDialog *dialog)
{
    if (g_strcmp0 (gtk_entry_get_text (GTK_ENTRY (entry)), "") != 0 &&
	g_strcmp0 (gtk_entry_get_text (GTK_ENTRY (entry)),  details.conflict_name) != 0)
    {
	gtk_widget_hide (details.replace_button);
	gtk_widget_show (details.rename_button);

	gtk_widget_set_sensitive (details.checkbox, FALSE);

	gtk_dialog_set_default_response (GTK_DIALOG (dialog),
					 CONFLICT_RESPONSE_RENAME);
    } 
    else 
    {
	gtk_widget_hide (details.rename_button);
	gtk_widget_show (details.replace_button);

	gtk_widget_set_sensitive (details.checkbox, TRUE);

	gtk_dialog_set_default_response (GTK_DIALOG (dialog),
					 CONFLICT_RESPONSE_REPLACE);
    }
}
static void
_reset_button_clicked_cb (GtkButton *w, GtkDialog *dialog)
{
    int start_pos, end_pos;

    gtk_entry_set_text (GTK_ENTRY (details.entry), details.conflict_name);
    gtk_widget_grab_focus (details.entry);
    eel_filename_get_rename_region (details.conflict_name,
				    &start_pos, &end_pos);
    gtk_editable_select_region (GTK_EDITABLE (details.entry),
				start_pos, end_pos);
}
static void
_checkbox_toggled_cb (GtkToggleButton *t, GtkDialog *dialog)
{
    gtk_widget_set_sensitive (details.expander,
	                      !gtk_toggle_button_get_active (t));
    gtk_widget_set_sensitive (details.rename_button,
	                      !gtk_toggle_button_get_active (t));

    if (!gtk_toggle_button_get_active (t) &&
	g_strcmp0 (gtk_entry_get_text (GTK_ENTRY (details.entry)),"") != 0 &&
	g_strcmp0 (gtk_entry_get_text (GTK_ENTRY (details.entry)),
		   details.conflict_name) != 0) 
    {
	gtk_widget_hide (details.replace_button);
	gtk_widget_show (details.rename_button);
    }
    else 
    {
	gtk_widget_hide (details.rename_button);
	gtk_widget_show (details.replace_button);
    }
}
#if 0
static void
_file_icons_changed (GFile *file, GtkDialog *fcd)
{
    GdkPixbuf *pixbuf;

    pixbuf = nautilus_file_get_icon_pixbuf (fcd->details->destination, NAUTILUS_ICON_SIZE_LARGE,
					    TRUE, NAUTILUS_FILE_ICON_FLAGS_USE_THUMBNAILS);

    gtk_image_set_from_pixbuf (GTK_IMAGE (fcd->details->dest_image), pixbuf);
    g_object_unref (pixbuf);

    pixbuf = nautilus_file_get_icon_pixbuf (fcd->details->source, NAUTILUS_ICON_SIZE_LARGE,
	                                    TRUE, NAUTILUS_FILE_ICON_FLAGS_USE_THUMBNAILS);

    gtk_image_set_from_pixbuf (GTK_IMAGE (fcd->details->src_image), pixbuf);
    g_object_unref (pixbuf);
}
#endif
//eel stuff copied from nautilus
static char *
eel_filename_get_extension_offset (const char *filename)
{
	char *end, *end2;

	end = strrchr (filename, '.');

	if (end && end != filename) {
		if (strcmp (end, ".gz") == 0 ||
		    strcmp (end, ".bz2") == 0 ||
		    strcmp (end, ".sit") == 0 ||
		    strcmp (end, ".Z") == 0) {
			end2 = end - 1;
			while (end2 > filename &&
			       *end2 != '.') {
				end2--;
			}
			if (end2 != filename) {
				end = end2;
			}
		}
	}

	return end;
}

static char *
eel_filename_strip_extension (const char * filename_with_extension)
{
	char *filename, *end;

	if (filename_with_extension == NULL) {
		return NULL;
	}

	filename = g_strdup (filename_with_extension);
	end = eel_filename_get_extension_offset (filename);

	if (end && end != filename) {
		*end = '\0';
	}

	return filename;
}

static void
eel_filename_get_rename_region (const char           *filename,
				int                  *start_offset,
				int                  *end_offset)
{
	char *filename_without_extension;

	g_return_if_fail (start_offset != NULL);
	g_return_if_fail (end_offset != NULL);

	*start_offset = 0;
	*end_offset = 0;

	g_return_if_fail (filename != NULL);

	filename_without_extension = eel_filename_strip_extension (filename);
	*end_offset = g_utf8_strlen (filename_without_extension, -1);

	g_free (filename_without_extension);
}

#if 0
#include <string.h>
#include <glib-object.h>
#include <gio/gio.h>
#include <glib/gi18n.h>
#include <pango/pango.h>
#include <eel/eel-vfs-extensions.h>

#include "nautilus-file.h"
#include "nautilus-icon-info.h"
#include "fileops_error_dialog.h"



G_DEFINE_TYPE (NautilusFileConflictDialog,
	       nautilus_file_conflict_dialog,
	       GTK_TYPE_DIALOG);

#define NAUTILUS_FILE_CONFLICT_DIALOG_GET_PRIVATE(object)		\
	(G_TYPE_INSTANCE_GET_PRIVATE ((object), NAUTILUS_TYPE_FILE_CONFLICT_DIALOG, \
				      NautilusFileConflictDialogDetails))


/*
 *	DONE.
 */
GtkWidget *
fileops_file_conflict_dialog_new (GtkWindow *parent,
				   GFile *source,
				   GFile *destination,
				   GFile *dest_dir)
{
	GtkWidget *dialog;
	dialog = GTK_WIDGET (g_object_new (FILEOPS_TYPE_FILE_CONFLICT_DIALOG,
			     "title", _("File conflict"),  NULL));

	FileOpsFileConflictDialogDetails *details;
	details = FILEOPS_FILE_CONFLICT_DIALOG(dialog)->details;

	details->source = source;
	details->destination = destination;
	details->dest_dir = dest_dir;

	gtk_window_set_transient_for (GTK_WINDOW (dialog), parent);

	return dialog;
}
//utility functions
static void
do_finalize (GObject *self)
{
	NautilusFileConflictDialogDetails *details =
		NAUTILUS_FILE_CONFLICT_DIALOG (self)->details;

	g_free (details->conflict_name);

	if (details->handle != NULL) {
		nautilus_file_list_cancel_call_when_ready (details->handle);
	}

	if (details->src_handler_id) {
		g_signal_handler_disconnect (details->source, details->src_handler_id);
		nautilus_file_monitor_remove (details->source, self);
	}

	if (details->dest_handler_id) {
		g_signal_handler_disconnect (details->destination, details->dest_handler_id);
		nautilus_file_monitor_remove (details->destination, self);
	}

	nautilus_file_unref (details->source);
	nautilus_file_unref (details->destination);
	nautilus_file_unref (details->dest_dir);

	G_OBJECT_CLASS (nautilus_file_conflict_dialog_parent_class)->finalize (self);
}

static void
nautilus_file_conflict_dialog_class_init (NautilusFileConflictDialogClass *klass)
{
	G_OBJECT_CLASS (klass)->finalize = do_finalize;

	g_type_class_add_private (klass, sizeof (NautilusFileConflictDialogDetails));
}

char *
nautilus_file_conflict_dialog_get_new_name (NautilusFileConflictDialog *dialog)
{
	return g_strdup (gtk_entry_get_text
			 (GTK_ENTRY (dialog->details->entry)));
}

gboolean
nautilus_file_conflict_dialog_get_apply_to_all (NautilusFileConflictDialog *dialog)
{
	return gtk_toggle_button_get_active 
		(GTK_TOGGLE_BUTTON (dialog->details->checkbox));
}
#endif 
