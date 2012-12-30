#include <string.h>

#include <gtk/gtk.h>

#include "fileops.h"
#include "fileops_clipboard.h"

/*
 * 	TODO: if we cut or copy files in nautilus, 
 * 	      how can we get notified?
 */

static GtkClipboard*		fileops_clipboard = NULL;
static gboolean			is_clipboard_owner = FALSE;
//we're not using pointers here
static FileOpsClipboardInfo	clipboard_info = {
                                .file_list = NULL,
				.num       = 0,
				.cut       = FALSE,
				};
// used to store data requested from another owner.
static FileOpsClipboardInfo	clipboard_info_tmp = { 
                                .file_list = NULL,
				.num       = 0,
				.cut       = FALSE,
				};	
static GdkAtom			copied_files_atom = GDK_NONE;	
static GdkWindow*		window; //the window receives owner-change event

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
//check if we're current the owner of the clipboard.
//static gboolean __is_owner_of_clipboard	();
//return true if valid clipboard, otherwise, FALSE
static gboolean __request_clipboard_contents (FileOpsClipboardInfo* info);
//get clipboard data from others.
static void __clipboard_contents_received_callback (GtkClipboard     *clipboard,
						    GtkSelectionData *selection_data,
						    gpointer          info);

gboolean
is_clipboard_empty ()
{
    if (copied_files_atom == GDK_NONE)
	copied_files_atom = gdk_atom_intern ("x-special/gnome-copied-files", FALSE);
    //TODO: we may not own the clipboard now
    if (is_clipboard_owner)
    {
	g_debug ("is_clipboard_empty: we're the owner of clipboard");
	if (clipboard_info.num)
	    return FALSE;

	return TRUE;
    }
    else
    {
	g_debug ("is_clipboard_empty: we're not the owner of clipboard");
	if (__request_clipboard_contents (&clipboard_info_tmp))
	{
	    //valid clipboard data;
	    return FALSE;
	}
	return TRUE;
    }
}

//TODO: multiple copy, single cut.
//  or  single copy, single cut.
void 
fileops_paste (GFile* dest_dir)
{
    if (copied_files_atom == GDK_NONE)
	copied_files_atom = gdk_atom_intern ("x-special/gnome-copied-files", FALSE);
    //TODO: we may not own the clipboard now
    //cut : move files
    //use clipboard_info or clipboard_info_tmp
    FileOpsClipboardInfo* real_info = NULL;

    if (is_clipboard_owner)
    {
	g_debug ("fileops_paste: we use our clipboard info");
	real_info = &clipboard_info;
    }
    else
    {
	g_debug ("fileops_paste: we use other clipboard_info");
	if (__request_clipboard_contents (&clipboard_info_tmp))
	    real_info = &clipboard_info_tmp;
    }

    if (real_info == NULL || real_info->num == 0)
	return;

    if (real_info->cut)	
    {
	fileops_move (real_info->file_list, real_info->num, dest_dir);

	__free_clipboard_info (real_info);
    }
    else
    {
	//copy can be done multiple times. so we should not free real_info;
	fileops_copy (real_info->file_list, real_info->num, dest_dir);
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

    if (copied_files_atom == GDK_NONE)
	copied_files_atom = gdk_atom_intern ("x-special/gnome-copied-files", FALSE);

    if (is_clipboard_owner)
	return;

    //TODO: request clipboard data before take ownership
    //      so we can interoperate with nautilus.
    if (fileops_clipboard == NULL)
    {
	fileops_clipboard = gtk_clipboard_get (GDK_SELECTION_CLIPBOARD);
	g_signal_connect (fileops_clipboard, "owner-change", 
		          G_CALLBACK (_clipboard_owner_change_cb), NULL);
    }

    target_list = gtk_target_list_new (NULL, 0);
    gtk_target_list_add (target_list, copied_files_atom, 0, 0);
    gtk_target_list_add_uri_targets (target_list, 0);
    gtk_target_list_add_text_targets (target_list, 0);

    targets = gtk_target_table_new_from_list (target_list, &n_targets);

    gtk_clipboard_set_with_data (fileops_clipboard,
				 targets, n_targets,
				 _get_clipboard_callback, _clear_clipboard_callback,
				 NULL);

    gtk_target_list_unref (target_list);
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
	if (is_clipboard_owner)
	{
	    g_debug ("_clipboard_owner_change_cb: we lost clipboard ownership");
	    is_clipboard_owner = FALSE;
	    __free_clipboard_info (&clipboard_info);
	}
	else
	{
	    g_debug ("_clipboard_owner_change_cb:  we gain clipboard ownership");
           // gtk_clipboard_clear (fileops_clipboard);
	    is_clipboard_owner = TRUE;
	}
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
//	__free_clipboard_info (&clipboard_info);
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
    g_debug ("free clipboard info : begin");
    if (info->file_list == NULL)
    {
	g_debug ("already freed");
	return;
    }

    int i;
    for (i = 0; i < info->num; i++)
    {
	g_object_unref (info->file_list[i]);
    }
    g_free (info->file_list);
    info->file_list = NULL;
    info->num = 0;
    g_debug ("free clipboard info : end");
}
#if 0
static gboolean 
__is_owner_of_clipboard	()
{
   if ((fileops_clipboard == NULL) || 
       (gtk_clipboard_get_owner (fileops_clipboard) == NULL))
      return FALSE; 
   return TRUE;
}
#endif
/*
 *	get data from clipboard ownered by others.
 */
static gboolean
__request_clipboard_contents (FileOpsClipboardInfo* info)
{
    g_debug ("__request_clipboard_contents: begin");
    //gtk_clipboard_request_contents (gtk_clipboard_get (GDK_SELECTION_CLIPBOARD),
    //				    copied_files_atom,
    //				    __clipboard_contents_received_callback,
    //				    info);
    // Use synchronous version 
    GtkSelectionData * selection_data;
    selection_data = gtk_clipboard_wait_for_contents (gtk_clipboard_get (GDK_SELECTION_CLIPBOARD),
				                      copied_files_atom);
    __clipboard_contents_received_callback (NULL, selection_data, info);
    g_debug ("__request_clipboard_contents: end");
    return info->num ? TRUE : FALSE;
}
static void
__clipboard_contents_received_callback (GtkClipboard     *clipboard,
				        GtkSelectionData *selection_data,
				        gpointer          info)
{
    g_debug ("__clipboard_contents_received_callback: begin");
    FileOpsClipboardInfo* _info = (FileOpsClipboardInfo*) info;

    __free_clipboard_info (info);

    _info->num = 0;
    _info->cut = FALSE;

    if (selection_data == NULL)
	return;

    if (gtk_selection_data_get_data_type (selection_data) != copied_files_atom)
	return;

    int _len = gtk_selection_data_get_length (selection_data);
    if (_len <= 0)
	return;

    guchar *data;
	
    data = (guchar *) gtk_selection_data_get_data (selection_data);
    data[_len] = '\0';

    char **lines;
    lines = g_strsplit (data, "\n", 0);

    //fill FileOpsClipboardInfo* info
    if (lines[0] == NULL) 
	return;

    if (strcmp (lines[0], "cut") == 0) 
	_info->cut = TRUE;
    else if (strcmp (lines[0], "copy") != 0) 
	return;

    int i;
    //get the number of files
    for (i = 1; lines[i] != NULL; i++) 
	_info->num ++;
    //FIXME: avoid another loop
    _info->file_list = g_malloc (_info->num * sizeof (GFile*));
    g_debug ("operation: %s", lines[0]);
    for (i = 1; lines[i] != NULL; i++) 
    {
	g_debug ("%d file: %s", i, lines[i]);
	//NOTE: i-1
	_info->file_list[i-1] = g_file_new_for_uri (lines[i]);
    }

    g_strfreev (lines);
    
    g_debug ("__clipboard_contents_received_callback: end");
}
