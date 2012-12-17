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

#ifndef _FILEOPS_H_
#define _FILEOPS_H_

#include <gdk/gdk.h>
#include <gtk/gtk.h>

G_BEGIN_DECLS

typedef enum _FileOpsFlags	FileOpsFlags;

enum _FileOpsFlags
{
    FILE_OPS_NONE,
    FILE_OPS_DELETE,
    FILE_OPS_TRASH,
    FILE_OPS_MOVE,
    FILE_OPS_COPY,
};

typedef gboolean (*GFileProcessingFunc) (GFile* file, gpointer data);

gboolean traverse_directory (GFile* dir, 
			     GFileProcessingFunc pre_hook,
			     GFileProcessingFunc post_hook, 
			     gpointer data);


gboolean fileops_dmx	(FileOpsFlags flags, const char* file_list[], guint num, ...);

//NOTE: all file paths should not have any trailing path separators.
gboolean fileops_delete (const char* file_list[], guint num);
gboolean fileops_trash	(const char* file_list[], guint num);
//@dest is a directory
gboolean fileops_move	(const char* file_list[], guint num, const char* dest);
gboolean fileops_copy	(const char* file_list[], guint num, const char* dest);

G_END_DECLS
#endif
