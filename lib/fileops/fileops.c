/**
 	Author : hooke

    This file is part of deepin-desktop. 

    This file is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This file is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with deepin-desktop.  If not, see <http://www.gnu.org/licenses/>.
**/
/*
 *	standard GIO implementation doesn't directly support
 *	traversing the filesystem hierachy. 
 *	so we need to implement one.
 */
#include "fileops.h"


static FileOpsFlags fileops;

/*static GdkDisplay*	display;*/
// PRIMARY, SECONDARY and CLIPBOARD are 
// predefined atoms, so we don't need to intern them
/*static GdkAtom		

void 
init_fileops_atoms (void)
{
    display = gdk_display_get_default ();

    gdk_atom_intern (
}*/

static gboolean _dummy_func		(GFile* file, gpointer data);

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
    GFileEnumerator* filenumerator;

    filenumerator = g_file_enumerate_children (dir, 
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
		return TRUE;
	    default:
		break;
	}
	g_error ("error : %s", error->message);
	g_error_free (error);
    }

    //here, we must be in a directory.
    pre_hook (dir, data);		//create dir if no exist.
    char* abs_cur_dir_path = NULL;
    abs_cur_dir_path = g_file_get_path (dir);

    g_debug ("traverse_directory: chdir to : %s", abs_cur_dir_path);
    g_chdir (abs_cur_dir_path);

    GFileInfo* file_info;
    while ((file_info = g_file_enumerator_next_file (filenumerator, NULL, &error)) != NULL)
    {
	const char* gfile_name = g_file_info_get_name (file_info);
	g_debug ("traverse_directory: %s", gfile_name);

	GFile* gfile = g_file_new_for_path (gfile_name); 
	GFile* dest_gfile = (GFile*) data;
	if (data != NULL)
	{
	    char* parent_name = g_file_get_path (dest_gfile);
	    char* dest_name = g_build_filename (parent_name,"/", gfile_name, NULL);
	    dest_gfile = g_file_new_for_path(dest_name);
	    g_debug ("traverse_directory: dest file: %s", dest_name);
	}

	//TODO:
	traverse_directory (gfile, pre_hook, post_hook, dest_gfile);
	
	g_free (gfile_name);
    }
    //checking errors
    if (error != NULL)
    {
	switch (error->code)
	{
	}
	g_error ("traverse_directory: %s", abs_cur_dir_path);
	g_error ("error : %s", error->message);
	g_error_free (error);
    }

    //close enumerator.
    g_file_enumerator_close (filenumerator, NULL, &error);
    //change to parent directory.
    g_debug ("traverse_directory: come out: %s", abs_cur_dir_path);
    g_free (abs_cur_dir_path);
    g_chdir ("..");

    //after processing child node. processing this directory.
    post_hook (dir, data);

    return TRUE;
}

/*
 *	demultiplexing file operations
 */
gboolean
fileops_dmx (FileOpsFlags ops, const char* file_list[], guint num, ...)
{
    gboolean ret = FALSE;
    const char* dest;
    
    va_list ap;
    va_start (ap, num);
    switch (ops)
    {
	case FILE_OPS_DELETE:
	    ret = fileops_delete (file_list, num);
	    break;
	case FILE_OPS_TRASH:
	    ret = fileops_trash (file_list, num);
	    break;
	case FILE_OPS_MOVE:
	    dest = va_arg (ap, char*);
	    ret = fileops_move (file_list, num, g_strdup (dest));
	    break;
	case FILE_OPS_COPY:
	    dest = va_arg (ap, char*);
	    ret = fileops_copy (file_list, num, g_strdup (dest));
	    break;
	default:
	    break;
    }
    va_end (ap);
    return ret;
}

/*
 *	@file_list : files(or directories) to delete.
 *	@num	   : number of files(or directories) in file_list
 *	pre_hook =NULL
 *	post_hook = _delete_files_async
 */
gboolean
fileops_delete (const char* file_list[], guint num)
{
    g_debug ("fileops_delete: Begin deleting files");
    int i;
    for (i = 0; i < num; i++)
    {
	g_debug ("fileops_delete: file %d: %s", i, file_list[i]);
	GFile* dir = g_file_new_for_path (file_list[i]);
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
gboolean
fileops_trash (const char* file_list[], guint num)
{
    g_debug ("fileops_trash: Begin trashing files");
    int i;
    for (i = 0; i < num; i++)
    {
	g_debug ("fileops_trash: file %d: %s", i, file_list[i]);
	GFile* dir = g_file_new_for_path (file_list[i]);
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
gboolean
fileops_move (const char* file_list[], guint num, const char* dest)
{
    g_debug ("fileops_move: Begin moving files");
    int i;
    for (i = 0; i < num; i++)
    {
	g_debug ("fileops_move: file %d: %s to dest: %s", i, file_list[i], dest);
	GFile* dir = g_file_new_for_path (file_list[i]);
	GFile* dest_dir = g_file_new_for_path (dest);
	//make sure dest_dir is a directory before proceeding.
	GFileType type = g_file_query_file_type (dest_dir, G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS, NULL);
	if (type != G_FILE_TYPE_DIRECTORY)
	{
	    return FALSE;
	}
	char* orig_basename = g_path_get_basename (file_list[i]);
	char* move_dest = g_build_filename (dest, "/", orig_basename, NULL);
	GFile* move_dest_gfile = g_file_new_for_path (move_dest);
	
	g_free (orig_basename);
	g_free (move_dest);

	_move_files_async (dir, move_dest_gfile);
	//traverse_directory (dir, _move_files_async, _dummy_func, move_dest_gfile);
    }
    g_debug ("fileops_move: End moving files");
}
/*
 *	@file_list : files(or directories) to trash.
 *	@num	   : number of files(or directories) in file_list
 *	pre_hook = _copy_files_async
 *	post_hook = NULL
 */
gboolean
fileops_copy (const char* file_list[], guint num, const char* dest)
{
    g_debug ("fileops_copy: Begin copying files");
    int i;
    for (i = 0; i < num; i++)
    {
	g_debug ("fileops_copy: file %d: %s to dest: %s", i, file_list[i], dest);
	GFile* dir = g_file_new_for_path (file_list[i]);
	GFile* dest_dir = g_file_new_for_path (dest);
	//make sure dest_dir is a directory before proceeding.
	GFileType type = g_file_query_file_type (dest_dir, G_FILE_QUERY_INFO_NOFOLLOW_SYMLINKS, NULL);
	if (type != G_FILE_TYPE_DIRECTORY)
	{
	    return FALSE;
	}
	char* orig_basename = g_path_get_basename (file_list[i]);
	char* copy_dest = g_build_filename (dest, "/", orig_basename, NULL);
	g_debug ("copy_dest=%s", copy_dest);
	GFile* copy_dest_gfile = g_file_new_for_path (copy_dest);
	
	g_free (orig_basename);
	g_free (copy_dest);

	traverse_directory (dir, _copy_files_async, _dummy_func, copy_dest_gfile);
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
    g_file_delete (file, NULL, &error);
    if (error != NULL)
    {
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
