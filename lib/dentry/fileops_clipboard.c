#include <gtk/gtk.h>

#include "fileops.h"
#include "fileops_clipboard.h"

/*
 * 	TODO: if we cut or copy files in nautilus, 
 * 	      how can we get notified?
 */

static GtkClipboard*		fileops_clipboard ;
static FileOpsClipboardInfo	clipboard_info;	//we're not using pointers here
static GdkAtom		copied_files_atom;	

static void _clipboard_owner_change_cb	(GtkClipboard*		clipboard,
					 GdkEventOwnerChange*	event,
					 gpointer		callback_data);
static void _get_clipboard_callback	(GtkClipboard*		clipboard,
					 GtkSelectionData*	selection_data,
					 guint			info,
					 gpointer               user_data);
static void _clear_clipboard_callback	(GtkClipboard *clipboard,
					 gpointer      user_data);
//internal functions used by callback
static char*__convert_file_list_to_string (FileOpsClipboardInfo *info,
			       		   gboolean format_for_text,
                               		   gsize *len);
//NOTE: @info itself is not freed.Yep, some inconsistency here.
static void __free_clipboard_info	(FileOpsClipboardInfo* info);

gboolean
is_clipboard_empty ()
{
    //TODO: we may not own the clipboard now
    if (clipboard_info.num)
	return FALSE;
    return TRUE;
}

//TODO: multiple copy, single cut.
//  or  single copy, single cut.
void 
fileops_paste (GFile* dest_dir)
{
    //TODO: we may not own the clipboard now
    //cut : move files
    if (clipboard_info.cut)	
    {
	fileops_move (clipboard_info.file_list, clipboard_info.num, dest_dir);

	gtk_clipboard_clear (fileops_clipboard);
	__free_clipboard_info (&clipboard_info);
    }
    //copy: copy files
    else
    {
	fileops_copy (clipboard_info.file_list, clipboard_info.num, dest_dir);
    }
}
/*
 * 	main entry point for cut and copy operations
 * 	cut : cut = TRUE;
 * 	copy: cut = FALSE;
 *
 * 	NOTE: every we cut or copy, we need to override
 * 	      previous data in clipboard.so we acquire
 * 	      clipboard every time we cut or copy.
 * 	      _clipboard_owner_change_cb is used to clear
 * 	      clipboard
 */
void 
init_fileops_clipboard (GFile* file_list[], guint num, gboolean cut)
{
    g_debug ("init_fileops_clipboard:begin");
    //set clipboard_info
    clipboard_info.file_list = (GFile**)g_malloc (num * sizeof (GFile*));
    int i;
    for (i = 0; i < num; i++)
    {
	clipboard_info.file_list[i] = g_object_ref (file_list[i]);
    }
    clipboard_info.num = num;
    clipboard_info.cut = cut;

    GtkTargetList*  target_list;
    GtkTargetEntry* targets;
    gint	    n_targets;

    copied_files_atom = gdk_atom_intern ("x-special/gnome-copied-files", FALSE);

    //TODO: request clipboard data before take ownership
    //      so we can interoperate with nautilus.
    fileops_clipboard = gtk_clipboard_get (GDK_SELECTION_CLIPBOARD);
    g_signal_connect (fileops_clipboard, "owner-change", G_CALLBACK (_clipboard_owner_change_cb), NULL);

    target_list = gtk_target_list_new (NULL, 0);
    gtk_target_list_add (target_list, copied_files_atom, 0, 0);
    gtk_target_list_add_uri_targets (target_list, 0);
    gtk_target_list_add_text_targets (target_list, 0);

    targets = gtk_target_table_new_from_list (target_list, &n_targets);
    gtk_target_list_unref (target_list);

    gtk_clipboard_set_with_data (fileops_clipboard,
				 targets, n_targets,
				 _get_clipboard_callback, _clear_clipboard_callback,
				 NULL);
    gtk_target_table_free (targets, n_targets);
    g_debug ("init_fileops_clipboard:end");
}


/*
 *	in response to "owner-change" signal.
 *	i.e. SelectionClear event.
 *
 *	release clipboard object and related data.
 */
static void 
_clipboard_owner_change_cb (GtkClipboard*		clipboard,
			    GdkEventOwnerChange*	event,
			    gpointer		        callback_data)
{
	g_debug ("_clipboard_owner_change_cb: begin");
	//TODO: shall we clear up clipboard data?
	//gtk_clipboard_clear (fileops_clipboard);
//	__free_clipboard_info (&clipboard_info);
	g_debug ("_clipboard_owner_change_cb: end");
}

static void 
_get_clipboard_callback	(GtkClipboard*		clipboard,
			 GtkSelectionData*	selection_data,
			 guint			info,
			 gpointer               user_data)
{
	g_debug ("_get_clipboard_callback: begin");
	GdkAtom target;
	target = gtk_selection_data_get_target (selection_data);

	// set to a URI string
        if (gtk_targets_include_uri (&target, 1)) 
	{
		char **uris;
		uris = g_malloc ((clipboard_info.num + 1) * sizeof (char *));

		int i = 0;
		for (i = 0; i < clipboard_info.num; i++)
	       	{
			uris[i] = g_file_get_uri (clipboard_info.file_list[i]);
			i++;
		}
		uris[i] = NULL;

		gtk_selection_data_set_uris (selection_data, uris);
		g_strfreev (uris);
        }
	// set to a UTF-8 encoded string
       	else if (gtk_targets_include_text (&target, 1))
       	{
                char *str;
                gsize len;
                str = __convert_file_list_to_string (&clipboard_info, TRUE, &len);

                gtk_selection_data_set_text (selection_data, str, len);
                g_free (str);
        } 
	//NOTE: cut or copy
	else if (target == copied_files_atom) 
	{
                char *str;
                gsize len;
                str = __convert_file_list_to_string (&clipboard_info, FALSE, &len);

                gtk_selection_data_set (selection_data, copied_files_atom, 8, str, len);
                g_free (str);
        }
	g_debug ("_get_clipboard_callback: end");
}
static void 
_clear_clipboard_callback (GtkClipboard *clipboard,
			   gpointer      user_data)
{
	g_debug ("_clear_clipboard_callback: begin");
	//gtk_clipboard_clear (clipboard);
	//TODO: notify others, 
	gtk_clipboard_clear (fileops_clipboard);
	__free_clipboard_info (&clipboard_info);
	g_debug ("_clear_clipboard_callback: end");
}
/*
 * 	@format_for_text : TRUE: (<parse_name> '\n')* <parse_name>
 * 	                   FALSE: ["cut"|"copy"]('\n' <uri>)* <uri>
 */
static char *
__convert_file_list_to_string (FileOpsClipboardInfo *info,
			       gboolean format_for_text,
                               gsize *len)
{
	g_debug ("__convert_file_list_to_string: begin");
	GString *uris;
	if (format_for_text)
		uris = g_string_new (NULL);
	else 
		uris = g_string_new (info->cut ? "cut" : "copy");
	
	char *uri, *tmp;
	GFile *f;
        guint i;
        for (i = 0; i < info->num; i++) 
	{
		uri = g_file_get_uri (info->file_list[i]);

		if (format_for_text)
	       	{
			f = g_file_new_for_uri (uri);
			tmp = g_file_get_parse_name (f);
			g_object_unref (f);
			
			if (tmp != NULL)
		       	{
				g_string_append (uris, tmp);
				g_free (tmp);
			} 
			else 
			{
				g_string_append (uris, uri);
			}
			/* skip newline for last element */
			if (i + 1 < info->num)
		       	{
				g_string_append_c (uris, '\n');
			}
		} 
		else 
		{
			g_string_append_c (uris, '\n');
			g_string_append (uris, uri);
		}

		g_free (uri);
	}

        *len = uris->len;
	
	g_debug ("__convert_file_list_to_string: begin");
	return g_string_free (uris, FALSE);
}
static void 
__free_clipboard_info	(FileOpsClipboardInfo* info)
{
    int i;
    for (i = 0; i < info->num; i++)
    {
	g_object_unref (info->file_list[i]);
    }
    g_free (info->file_list);
}
