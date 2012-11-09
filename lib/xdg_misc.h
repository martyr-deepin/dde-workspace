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



/*---------------------------------
 * below functions and struct only need when you want write your own desktop entry feature.
 * -------------------------------
 */

// get the $XDG_DESKTOP_DIR value
char* get_desktop_dir(gboolean update);


// convert the icon name to the really icon path, seea also "set_default_theme"
char* icon_name_to_path(const char* name, int size);


typedef struct _BaseEntry {
    char* entry_path;
    char* type;
    char* version;

    char* name;  //localestring

    char* generic_name; //localestring
    gboolean no_display;
    char* comment; //localestring
    char* icon; //localestring
    gboolean hidden;
    char** only_show_in;
    char** not_show_in;


    /*
     * A list of strings which may be used in addition to other metadata to describe this entry. This can
     * be useful e.g. to facilitate searching through entries. The values are not meant for display, 
     * and should not be redundant with the values of Name or GenericName.
     */
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

    char* try_exec;
    char* exec;
    char exec_flag;

    /*
     * If entry is of type Application, the working directory to run the program in.
     */
    char* path; 

    /* 
     * Whether the program runs in a terminal window.
     */
    gboolean terminal; 

    /* Identifiers for application actions. This can be used to tell the application to make a 
     * specific action, different from the default behavior. The Application actions section describes
     * how actions work.
     */
    char** actions;

    /*
     * The MIME type(s) supported by this application.
     */
    char** mime_type; 

    /*
     * Categories in which the entry should be shown in a menu (for possible values see t
     * he Desktop Menu Specification).
     */
    char* categories;

    char** keywords;

    /*
     * If true, it is KNOWN that the application will send a "remove" message when started with the DESKTOP_STARTUP_ID environment variable set. If false, it is KNOWN that the application does not work with startup notification at all (does not shown any window, breaks even when using StartupWMClass, etc.). If absent, a reasonable handling is up to implementations (assuming false, using StartupWMClass, etc.). (See the Startup Notification Protocol Specification for more
     * details).
     */
    gboolean startup_notify;

    /*
     * If specified, it is known that the application will map at least one window with the given string 
     * as its WM class or WM name hint (see the Startup Notification Protocol Specification for more details).
     */
    char* startup_wmclass;

} ApplicationEntry ;

typedef struct _LinkEntry {
    struct _BaseEntry base;

    /*
     * If entry is Link type, the URL to access.
     */
    char* url;
} LinkEntry;

// didn't know what the "Directory" type meanings specified by xdg.
typedef struct _XDGDirectoryEntry {
    struct _BaseEntry base;
} XDGDirectoryEntry;

typedef struct _FileEntry {
    struct _BaseEntry base;

    char* exec;
} FileEntry;

typedef struct _DirectoryEntry {
    struct _BaseEntry base;

    char* files;
} DirectoryEntry;

#endif
