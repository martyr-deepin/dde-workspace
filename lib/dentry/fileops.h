#ifndef _FILEOPS_H_
#define _FILEOPS_H_

#include <gdk/gdk.h>
#include <gtk/gtk.h>



typedef gboolean (*GFileProcessingFunc) (GFile* file, gpointer data);

void dfile_delete	(GFile* file_list[], guint num);
void dfile_trash	(GFile* file_list[], guint num);


// this paste operation is a wrapper around fileops_move and fileops_copy, but read its 
// parameters from clipboard. see fileops_clipboard.c/h
void dfile_paste	();

//@dest is a directory
void dfile_move		(GFile* file_list[], guint num, GFile* dest_dir);
void dfile_copy		(GFile* file_list[], guint num, GFile* dest_dir);

#endif
