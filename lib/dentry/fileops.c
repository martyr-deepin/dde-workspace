/*
 *	standard GIO implementation doesn't directly support
 *	traversing the filesystem hierachy. 
 *	so we need to implement one.
 */
#include <glib/gstdio.h>

#include "fileops.h"


static gboolean _dummy_func		(GFile* file, gpointer data);

static void	_init_file_ops		(void);

static gboolean _delete_files_async	(GFile* file, gpointer data);
static gboolean _trash_files_async	(GFile* file, gpointer data);
static gboolean _move_files_async	(GFile* file, gpointer data);
static gboolean _copy_files_async	(GFile* file, gpointer data);

/*
 *	@dir	: file or directory to traverse 
 *	@pre_hook: pre-processing function, this used in move and copy
 *	@post_hook: post-processing function, this used in delete and trash.
 *	@data	: data passed to callback function.
 *	          currently we only use this as GFile* which is the fileops destination
 *	          corresponding to @dir. for each recursive level, we should update 
 *	          data to ensure that @dir and @data are consistent.
 *
 *	NOTE: 1.if dir is a file, applying callback and return.
 *	        if dir is a directory, traversing the directory tree 
 *	      2.we don't follow symbol links.
 *   	      3.there's a race condition in checking @dir type before 
 *		enumerating @dir. so we don't check @dir type. 
 *		if @dir is a file, we handle it in G_IO_ERROR_NOT_DIRECTORY.
 *	      4. (move, copy) and (delete, trash) behave differently.
 *	         (move, copy) first create the directory then create files in the directory
 *	         (delete, trash) first delete files in the directory then delete the directory
 *	         so we need a pre_hook and post_hook separately.
 *	       
 *
 *	TODO: change "standard::*" to the attributes we actually needed.
 */
gboolean
traverse_directory (GFile* dir, GFileProcessingFunc pre_hook, GFileProcessingFunc post_hook, gpointer data)
{
    GError* error = NULL;
    GFileEnumerator* dir_enumerator;

    dir_enumerator = g_file_enumerate_children (dir, 
					       "standard::*",
					       G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS,
					       NULL,
					       &error);
    if (error != NULL)
    {
	switch (error->code)
	{
	    case G_IO_ERROR_NOT_FOUND:
		//TODO: showup a message box and quit.
		break;
	    case G_IO_ERROR_NOT_DIRECTORY:
		//TODO:we're using a file.
		pre_hook  (dir, data);
		post_hook (dir, data);   //

		g_error_free (error);
		return TRUE;
	    default:
		break;
	}
	g_error ("error : %s", error->message);
	g_error_free (error);
    }

    //here, we must be in a directory.
    //check if it's a symbolic link
    if (pre_hook (dir, data) == FALSE)
	goto post_processing;		//create dir if not exist.
    
    char* abs_cur_dir_path = NULL;
    abs_cur_dir_path = g_file_get_path (dir);
    g_debug ("traverse_directory: chdir to : %s", abs_cur_dir_path);
    g_chdir (abs_cur_dir_path);

    GFileInfo* file_info = NULL;
    while ((file_info = g_file_enumerator_next_file (dir_enumerator, NULL, &error)) != NULL)
    {
	//this should not be freed with g_free(). it'll be freed when we call g_object_unref
	//on file_info
	const char* _file_name = g_file_info_get_name (file_info);
	g_debug ("traverse_directory: %s", _file_name);

	GFile* src_file = g_file_new_for_path (_file_name); 
	GFile* dest_file = NULL;
	if (data != NULL)
	{
	    GFile* dest_file = (GFile*) data;

	    char* _parent_name = g_file_get_path (dest_file);
	    char* _dest_name = g_build_filename (_parent_name,"/", _file_name, NULL);

	    dest_file = g_file_new_for_path(_dest_name);
	    g_debug ("traverse_directory: dest file: %s", _dest_name);
	
	    g_free (_parent_name);
	    g_free (_dest_name);
	}
	//TODO:
	traverse_directory (src_file, pre_hook, post_hook, dest_file);
	
	g_object_unref (src_file);
	if (dest_file != NULL)
	    g_object_unref (dest_file);
	g_object_unref (file_info);
	file_info = NULL;
    }
    //checking errors
    if (error != NULL)
    {
	g_error ("traverse_directory: %s", abs_cur_dir_path);
	g_error ("error : %s", error->message);
	g_error_free (error);
    }

    //close enumerator.
    g_file_enumerator_close (dir_enumerator, NULL, &error);
    g_object_unref (dir_enumerator);
    //checking errors
    if (error != NULL)
    {
	g_error ("error : %s", error->message);
	g_error_free (error);
    }
    //change to parent directory.
    g_debug ("traverse_directory: come out: %s", abs_cur_dir_path);
    g_free (abs_cur_dir_path);
    g_chdir ("..");

post_processing:
    //after processing child node. processing this directory.
    if (post_hook (dir, data) == FALSE)
	return TRUE;

    return TRUE;
}

/*
 *	@file_list : files(or directories) to delete.
 *	@num	   : number of files(or directories) in file_list
 *	pre_hook =NULL
 *	post_hook = _delete_files_async
 */
void
fileops_delete (GFile* file_list[], guint num)
{
    g_debug ("fileops_delete: Begin deleting files");
    int i;
    for (i = 0; i < num; i++)
    {
	GFile* dir = file_list[i];
	char* filename = g_file_get_path (dir);
	g_debug ("dfile_delete: file %d: %s", i, filename);
	g_free (filename);
	traverse_directory (dir, _dummy_func, _delete_files_async, NULL);
    }
    g_debug ("fileops_delete: End deleting files");
}
/*
 *	@file_list : files(or directories) to trash.
 *	@num	   : number of files(or directories) in file_list
 *	NOTE: trashing is special because we don't need to 
 *	      traverse_directory. the default implementation can 
 *	      recursively trash files.
 */
void
fileops_trash (GFile* file_list[], guint num)
{
    g_debug ("fileops_trash: Begin trashing files");
    int i;
    for (i = 0; i < num; i++)
    {
	GFile* dir = file_list[i];
	char* filename = g_file_get_path (dir);
	g_debug ("fileops_trash: file %d: %s", i, filename);
	g_free (filename);
	_trash_files_async (dir, NULL);
	//traverse_directory (dir, _dummy_func, _trash_files_async, NULL);
    }
    g_debug ("fileops_trash: End trashing files");
}
/*
 *	@file_list : files(or directories) to move.
 *	@num	   : number of files(or directories) in file_list
 *	@dest	   : destination directory.
 *
 *	NOTE: moving is special because we don't need to 
 *	      traverse_directory. the default implementation can 
 *	      recursively trash files.
 */
void
fileops_move (GFile* file_list[], guint num, GFile* dest_dir)
{
    g_debug ("fileops_move: Begin moving files");
    int i;
    for (i = 0; i < num; i++)
    {
	GFile* src_dir = file_list[i];
	char* src_name = g_file_get_path (src_dir);
	char* dest_name = g_file_get_path (dest_dir);
	g_debug ("fileops_move: file %d: %s to dest: %s", i, src_name, dest_name);

	//make sure dest_dir is a directory before proceeding.
	GFileType type = g_file_query_file_type (dest_dir, G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS, NULL);
	if (type != G_FILE_TYPE_DIRECTORY)
	{
	    return;
	}
	char* src_basename= g_path_get_basename (src_name);
	char* move_dest_name = g_build_filename (dest_name, "/", src_basename, NULL);
	GFile* move_dest_file = g_file_new_for_path (move_dest_name);
	
	g_free (src_name);
	g_free (dest_name);

	g_free (src_basename);
	g_free (move_dest_name);

	_move_files_async (src_dir, move_dest_file);
	//traverse_directory (dir, _move_files_async, _dummy_func, move_dest_gfile);
	g_object_unref (move_dest_file);
    }
    g_debug ("fileops_move: End moving files");
}
/*
 *	@file_list : files(or directories) to trash.
 *	@num	   : number of files(or directories) in file_list
 *	pre_hook = _copy_files_async
 *	post_hook = NULL
 */
void
fileops_copy (GFile* file_list[], guint num, GFile* dest_dir)
{
    g_debug ("fileops_copy: Begin copying files");
    int i;
    for (i = 0; i < num; i++) {
        GFile* src_dir = file_list[i];
        char* src_name = g_file_get_path (src_dir);
        char* dest_name = g_file_get_path (dest_dir);
        g_debug ("fileops_copy: file %d: %s to dest: %s", i, src_name, dest_name);

        //make sure dest_dir is a directory before proceeding.
        GFileType type = g_file_query_file_type (dest_dir, G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS, NULL);
        if (type != G_FILE_TYPE_DIRECTORY)
        {
            return;
        }
        char* src_basename = g_path_get_basename (src_name);
        char* copy_dest_name = g_build_filename (dest_name, "/", src_basename, NULL);
        GFile* copy_dest_file = g_file_new_for_path (copy_dest_name);

        g_free (src_name);
        g_free (dest_name);

        g_free (src_basename);
        g_free (copy_dest_name);

        traverse_directory (src_dir, _copy_files_async, _dummy_func, copy_dest_file);

        g_object_unref (copy_dest_file);
    }
    g_debug ("fileops_copy: End copying files");
}
// internal functions 
// TODO : setup a dialog, support Cancelling and show progress bar.

static gboolean 
_dummy_func (GFile* file, gpointer data)
{
    return TRUE;
}

static gboolean
_delete_files_async (GFile* file, gpointer data)
{
    GError* error = NULL;
    GCancellable* _delete_cancellable = g_cancellable_new ();

    g_file_delete (file, _delete_cancellable, &error);
    if (error != NULL)
    {
	//show error dialog
	g_cancellable_cancel (_delete_cancellable);
	g_error ("%s\n", error->message);
	g_error_free (error);
    }
    char* name = g_file_get_path (file);
    g_debug ("_delete_files_async: delete : %s", name);
    g_free (name);
}

static gboolean
_trash_files_async (GFile* file, gpointer data)
{
    GError* error = NULL;
    g_file_trash (file, NULL, &error);
    if (error != NULL)
    {
	g_error ("%s\n", error->message);
	g_error_free (error);
    }
    char* name = g_file_get_path (file);
    g_debug ("_trash_files_async: trash : %s", name);
    g_free (name);
}
/*
 *	@dest is a directory.	
 */
static gboolean
_move_files_async (GFile* file, gpointer data)
{
    GError* error = NULL;
    GFile* dest = (GFile*) data;
    g_file_move (file, dest,
	         G_FILE_COPY_NOFOLLOW_SYMLINKS,
		 NULL,
		 NULL,
		 NULL,
		 &error);
    if (error != NULL)
    {
	g_error ("%s", error->message);
	g_error_free (error);
    }

    char* name = g_file_get_path (file);
    char* dest_name = g_file_get_path (dest);
    g_debug ("_move_files_async: move %s to %s", name, dest_name);
    g_free (name);
    g_free (dest_name);
}
/*
 *  
 */
static gboolean
_copy_files_async (GFile* file, gpointer data)
{
    GError* error = NULL;
    GFile* dest = (GFile*) data;
    
    //because @dest doesn't exist, we should check @file instead.
    GFileType type = g_file_query_file_type (file, G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS, NULL);
    if (type == G_FILE_TYPE_DIRECTORY)
    {
	//TODO: change permissions
	g_file_make_directory (dest, NULL, &error);
	if (error != NULL)
	{
	    g_debug ("_copy_files_async: %s", error->message);
	}
	char* dir_name = g_file_get_path (dest);
	g_debug ("_copy_files_async: mkdir : %s", dir_name);
	g_free (dir_name);
    }
    else
    {
	g_file_copy (file, dest,
		       G_FILE_COPY_NOFOLLOW_SYMLINKS,
		       G_PRIORITY_DEFAULT,
		       NULL,
		       NULL,
		       &error);
	if (error != NULL)
	{
	    g_error ("%s", error->message);
	    g_error_free (error);
	}

	char* name = g_file_get_path (file);
	char* dest_name = g_file_get_path (dest);
	g_debug ("_copy_files_async: copy %s to %s", name, dest_name);
	g_free (name);
	g_free (dest_name);
    }
}
