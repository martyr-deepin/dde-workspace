/**
 * Copyright (c) 2011 ~ 2013 Deepin, Inc.
 *               2011 ~ 2013 Long Wei
 *
 * Author:      Long Wei <yilang2007lw@gmail.com>
 *              bluth <yuanchenglu001@gmail.com>
 * Maintainer:  Long Wei <yilang2007lw@gamil.com>
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

#include "lock_util.h"
#include "user.h"
#include "mutils.h"
/*#include "camera.h"*/

extern const gchar *username;

JS_EXPORT_API
const gchar* lock_get_username ()
{
    username = g_get_user_name ();
    return username;
}

JS_EXPORT_API
gchar *lock_get_user_realname (const gchar* name)
{
    // WHY NOT use name here???
    NOUSED(name);
    return get_user_realname (username);
}

JS_EXPORT_API
gchar* lock_get_user_icon (const gchar* name)
{
    // WHY NOT use name here???
    NOUSED(name);
    return get_user_icon (username);
}

JS_EXPORT_API
gboolean lock_need_password (const gchar* name)
{
    // WHY NOT use name here???
    NOUSED(name);
    return is_need_pwd (username);
}

JS_EXPORT_API
gchar* lock_get_date ()
{
   return get_date_string ();
}

JS_EXPORT_API
gboolean lock_detect_capslock ()
{
    return is_capslock_on ();
}

JS_EXPORT_API
void lock_switch_user ()
{
    GError *error = NULL;

    if (g_find_program_in_path ("dde-switchtogreeter") == NULL) {
        g_warning ("lock switch user:can't find dde-switchtogreeter\n");
        return ;
    }

    g_spawn_command_line_async ("dde-switchtogreeter", &error);
    if (error != NULL) {
        g_warning ("switch to greeter error:%s\n", error->message);
        g_error_free (error);
    } else {
        /*gtk_main_quit();*/
        g_message("face_login hide");
        /*destroy_camera();*/
    }
}

JS_EXPORT_API
void lock_draw_background (JSValueRef canvas)
{
    if (username == NULL) {
        username = lock_get_username ();
    }

    draw_user_background (canvas, username);
}

JS_EXPORT_API
gboolean lock_is_guest ()
{
    gboolean is_guest = FALSE;

    if (username == NULL) {
        username = lock_get_username ();
    }
    g_message("username:%s",username);
    if (g_str_has_prefix (username, "guest")) {
        gchar * name = get_user_realname (username);
        g_message("realname:%s",name);
        if (g_ascii_strncasecmp ("Guest", name, 5) == 0) {
            g_message ("lock is guest\n");
            is_guest = TRUE;
        }
        g_free (name);
    }

    return is_guest;
}

gboolean lock_is_running ()
{
    gboolean run_flag = FALSE;

    gchar *user_lock_path = NULL;
    if (username == NULL) {
        username = lock_get_username ();
    }

    user_lock_path = g_strdup_printf ("%s%s", username, ".dlock.app.deepin");
    if (app_is_running (user_lock_path)) {
        g_warning ("another instance of dlock is running by current user %s...\n",user_lock_path);
        run_flag = TRUE;
    }

    g_free (user_lock_path);

    return run_flag;
}

void lock_report_pid ()
{
    gchar *lockpid_file = NULL;
    if (username == NULL) {
        username = lock_get_username ();
    }

    lockpid_file = g_strdup_printf ("%s%s%s", "/home/", username, "/.dlockpid");
    if (g_file_test (lockpid_file, G_FILE_TEST_EXISTS)) {

        g_debug ("remove old pid info before lock");
        g_remove (lockpid_file);
    }

    if (g_creat (lockpid_file, O_RDWR) == -1) {
        g_warning ("touch lockpid_file failed\n");
    }

    gchar *contents = g_strdup_printf ("%d", getpid ());

    g_file_set_contents (lockpid_file, contents, -1, NULL);

    g_free (contents);
    g_free (lockpid_file);
}

