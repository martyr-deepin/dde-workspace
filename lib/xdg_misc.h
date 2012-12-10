/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 **/
#ifndef __XDG_MISC_H__
#define __XDG_MISC_H__
#include <glib.h>

// the really icon path is determined by theme
void set_default_theme(const char* theme);
// deal with the NotShowIn/OnlyShowIn filed. 
void set_desktop_env_name(const char* name);

// get all desktop entry under the dir of $XDG_DESKTOP_DIR
// include the normal file and dir, exclude the dot hidden file.
// return string is an valid JSON array
char* get_desktop_entries();

// get all system and user home's applications (eg, /usr/share/applications, ~/.local/share/applications)
// also include the executable file in $PATH, and will try to detect the icon of the executable file.
char* get_application_entries();

// move the "path" file to the $XDG_DESKTOP_DIR
// will auto append suffix if there has the same name file in $XDG_DESKTOP_DIR,
// but will do nothing if the "path" file is already in $XDG_DESKTOP_DIR
char* move_to_desktop(const char* path);

char* get_entry_info(const char* path);


typedef gboolean (*ENTRY_CONDITION)(const char*);
char* get_entries_by_func(const char* base_dir, ENTRY_CONDITION func);

// default ENTRY_CONDITION functions
gboolean only_normal_dir(const char* path);
gboolean only_desktop(const char* path);
gboolean only_normal_file(const char* path);
gboolean no_dot_hidden_file(const char* path);

// change the desktop file 's current locale name to "name"
gboolean change_desktop_entry_name(const char* path, const char* name);



/*---------------------------------
 * below functions and struct only need when you want write your own desktop entry feature.
 * -------------------------------
 */

// get the $XDG_DESKTOP_DIR value
char* get_desktop_dir(gboolean update);


// convert the icon name to the really icon path, seea also "set_default_theme"
char* icon_name_to_path(const char* name, int size);

enum EntryType {
    AppEntryType,
    FileEntryType,
    DirEntryType,
    LinkEntryType,
};

typedef struct _BaseEntry {
    char* entry_path;
    enum EntryType type;

    char* name;  //localestring

    char* icon; //localestring
} BaseEntry;

// parse the "path" file to the BaseEntry struct.
// this function will also parse the normal file and normal dir.
BaseEntry* parse_one_entry(const char* path);
BaseEntry* parse_desktop_entry(const char* path);
BaseEntry* parse_normal_file(const char* path);
char* entry_info_to_json(BaseEntry* _entry);

void desktop_entry_free(BaseEntry* entry);

typedef struct _ApplicationEntry {
    struct _BaseEntry base;
    char* exec;
    char exec_flag;
    char* categories;
} ApplicationEntry ;

typedef struct _FileEntry {
    struct _BaseEntry base;
    char* exec;
} FileEntry;

typedef struct _DirectoryEntry {
    struct _BaseEntry base;
    char* files;
} DirectoryEntry;

typedef struct _LinkEntry {
    struct _BaseEntry base;
    char* url;
} LinkEntry;

#endif
