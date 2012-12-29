#include <gtk/gtk.h>

#include "enums.h"
#include "fileops_error_dialog.h"

/*
 *	because we use dialog in applications which manages desktop.
 *	@parent is always NULL.
 */
static FileOpsResponse  _show_simple_error_message_dialog		(const char *fileops_str,
									 const char *error_message,
									 GFile* file,
									 GtkWindow* parent);
static FileOpsResponse	_show_skip_cancel_all_dialog			(const char *fileops_str,
									 const char *error_message,
									 GFile *file,
									 GtkWindow* parent);
static FileOpsResponse	_show_skip_cancel_replace_rename_all_dialog	(const char *fileops_str,
									 const char *error_message,
									 GFile *src, 
									 GFile *dest,
									 GtkWindow* parent);

/*
 *	delete, trash error need only one GFile* parameters. 
 *	@fileops_str : "delete" or "trash"
 *	@error:
 *	@file: file to delete or trash.
 */
FileOpsResponse
fileops_delete_trash_error_show_dialog (const char* fileops_str, GError* error, 
					GFile* file, GtkWindow* parent)
{
    FileOpsResponse ret;
    switch (error->code)
    {
	case G_IO_ERROR_PERMISSION_DENIED: 
	     ret = _show_skip_cancel_all_dialog (fileops_str, error->message, file, parent);
	     break;
	case G_IO_ERROR_CANCELLED:   
	    /*
	     * TODO: response: this is caused by progress_dialog. 
	     */
	     ret = _show_simple_error_message_dialog (fileops_str, error->message, file, parent);
	    break;

	case G_IO_ERROR_IS_DIRECTORY:  //programming error.
	case G_IO_ERROR_INVALID_ARGUMENT: //programming error
	     ret = _show_simple_error_message_dialog (fileops_str, "Programming error", NULL, parent);
	    break;
	default: //all other errors are not handled.
	     ret = _show_simple_error_message_dialog (fileops_str, "Unexpected error happens!", NULL, parent);
	    break;
    }

    return ret;
}
/*
 *	move, copy needs a src, and dest.
 *	@fileops_str : "move" or "copy"
 *	@src : source file 
 *	@dest: destinatin file.
 */
FileOpsResponse
fileops_move_copy_error_show_dialog (const char* fileops_str, GError* error, 
	                             GFile* src, GFile* dest, GtkWindow* parent)
{
    FileOpsResponse ret = FILE_OPS_RESPONSE_CANCEL;
    switch (error->code)
    {
	case G_IO_ERROR_EXISTS:      //move, copy
	    //TODO: message dialog.
	    //      overwrite, replace, rename, //all overwrite, replace all, rename all.
	    _show_skip_cancel_replace_rename_all_dialog (fileops_str, error->message, src, dest, parent);
	    break;
	case G_IO_ERROR_NOT_DIRECTORY: //move, copy destination
	    /*
	     * TODO: response: FILE_OPS_RESPONSE_CANCEL.
	     */
	    _show_simple_error_message_dialog (fileops_str, error->message, dest, parent);
	    break;
	case G_IO_ERROR_PERMISSION_DENIED: //delete, trash, move, copy
	    /*
	     * TODO: response: skip, cancel, //skip all
	     * NOTE: use @dest instead of @src here.
	     */
	    _show_skip_cancel_all_dialog (fileops_str, error->message, dest, parent);
	    break;
	case G_IO_ERROR_CANCELLED:   //operatin was cancelled
	    /*
	     * TODO: response: this is caused by progress_dialog. 
	     */
	    _show_simple_error_message_dialog (fileops_str, error->message, dest, parent);
	    break;

	case G_IO_ERROR_IS_DIRECTORY:  //programming error.
	case G_IO_ERROR_INVALID_ARGUMENT: //programming error
	    _show_simple_error_message_dialog (fileops_str, "Programming error !", NULL, parent);
	    break;
	default: //all other errors are not handled.
	    _show_simple_error_message_dialog (fileops_str, "Unexpected error happens!", NULL, parent);
	    break;
    }

    return ret;
}

//internal functions
/*
 *	when there're some unrecoverable errors, we use this dialog to prompt users.
 *	after calling this, we stop all operations.
 *	TODO:
 */
static FileOpsResponse  
_show_simple_error_message_dialog (const char* fileops_str, const char *error_message,
				   GFile *file, GtkWindow* parent)
{
    if (file == NULL)
    {
	//just show error_message and return.
    }
    //file != NULL:
    return FILE_OPS_RESPONSE_CANCEL;
}
/*
 *	permission denied, what we do now?
 *	TODO:
 */
static FileOpsResponse	
_show_skip_cancel_all_dialog (const char* fileops_str, const char *error_message, 
			      GFile* file, GtkWindow* parent)
{
    
    return FILE_OPS_RESPONSE_CANCEL;
}
/*
 *
 */
static FileOpsResponse	
_show_skip_cancel_replace_rename_all_dialog (const char *fileops_str, const char *error_message,
					     GFile *src, GFile *dest, GtkWindow* parent)
{
    
    GtkDialog* dialog = fileops_error_conflict_dialog_new (parent, src, dest);
    gtk_widget_show (GTK_WIDGET (dialog));

 //   FILE_OPS_RESPONSE_CANCEL   = 0,
  //  FILE_OPS_RESPONSE_CONTINUE = 1;

   // "error: file exists";
    //rename
    //all
    //cancel, skip, replace
}
