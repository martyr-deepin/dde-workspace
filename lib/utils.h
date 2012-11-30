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
#ifndef __UTILS_H__
#define __UTILS_H__

#include <glib.h>

#define GET_HTML_PATH(name) "file://"RESOURCE_DIR"/"name"/index.html"

char* json_escape (const char *source);
char* shell_escape(const char* source);
int is_application_running(const char* path);
void log_to_file(const gchar* log_domain, GLogLevelFlags log_level, const gchar* message, char* app_name);

char* gen_id(const char* seed);
void run_command(const char* cmd);
void run_command2(const char* cmd, const char* p1, const char* p2);
void run_command1(const char* cmd, const char* p1);
char* get_name_by_pid(int pid);

#endif
