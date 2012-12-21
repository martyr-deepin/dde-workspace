/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 Long Wei
 *
 * Author:      Long Wei <yilang2007lw@gmail.com>
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

#include <lightdm.h>
#include "jsextension.h"

/* GREETER */

LightDMGreeter* greeter_new()
{
    return lightdm_greeter_new();
}

gboolean greeter_connect_lightdm(LightDMGreeter *greeter)
{
    return lightdm_greeter_connect_sync(greeter, NULL);
}

const gchar* greeter_get_default_session(LightDMGreeter *greeter)
{
    return lightdm_greeter_get_default_session_hint(greeter);
}

gboolean greeter_support_guest(LightDMGreeter *greeter)
{
    return lightdm_greeter_get_has_guest_account_hint(greeter);
}

const gchar* greeter_get_default_user(LightDMGreeter *greeter)
{
    return lightdm_greeter_get_select_user_hint(greeter);
}

gboolean greeter_hide_users(LightDMGreeter *greeter)
{
    return lightdm_greeter_get_hide_users_hint(greeter);
}

gboolean greeter_get_guest_default(LightDMGreeter *greeter)
{
    return lightdm_greeter_get_select_guest_hint(greeter);
}

const gchar* greeter_get_autologin_user(LightDMGreeter *greeter)
{
    return lightdm_greeter_get_autologin_user_hint(greeter);
}

gboolean greeter_get_guest_autologin(LightDMGreeter *greeter)
{
    return lightdm_greeter_get_autologin_guest_hint(greeter);
}

gint greeter_get_autologin_timeout(LightDMGreeter *greeter)
{
    return lightdm_greeter_get_autologin_timeout_hint(greeter);
}

void greeter_cancel_autologin(LightDMGreeter *greeter)
{
    lightdm_greeter_cancel_autologin(greeter);
}

void greeter_authenticate(LightDMGreeter *greeter, const char *username)
{
    lightdm_greeter_authenticate(greeter, username);
}

void greeter_authenticate_guest(LightDMGreeter *greeter)
{
    lightdm_greeter_authenticate_as_guest(greeter);
}

void greeter_respond(LightDMGreeter *greeter, const gchar *response)
{
    lightdm_greeter_respond(greeter, response);
}

void greeter_cancel_authentication(LightDMGreeter *greeter)
{
    lightdm_greeter_cancel_authentication(greeter);
}

gboolean greeter_in_authentication(LightDMGreeter *greeter)
{
    return lightdm_greeter_get_in_authentication(greeter);
}

gboolean greeter_is_authenticated(LightDMGreeter *greeter)
{
    return lightdm_greeter_get_is_authenticated(greeter);
}

const gchar* greeter_get_authentication_user(LightDMGreeter *greeter)
{
    return lightdm_greeter_get_authentication_user(greeter);
}

gboolean greeter_start_session(LightDMGreeter *greeter, const gchar *session)
{
    return lightdm_greeter_start_session_sync(greeter, session, NULL);
}

/* SESSION */

GList* greeter_get_sessions()
{
    return lightdm_get_sessions();
}

const gchar* greeter_get_session_key(LightDMSession *session)
{
    return lightdm_session_get_key(session);
}

const gchar* greeter_get_session_name(LightDMSession *session)
{
    return lightdm_session_get_name(session);
}

const gchar* greeter_get_session_comment(LightDMSession *session)
{
    return lightdm_session_get_comment(session);
}

/* USER  */

const gchar* greeter_get_user_name(LightDMUser *user)
{
    return lightdm_user_get_name(user);
}

gboolean greeter_get_user_logged(LightDMUser *user)
{
    return lightdm_user_get_logged_in(user);
}

const gchar* greeter_get_user_image(LightDMUser *user)
{
    return lightdm_user_get_image(user);
}

const gchar* greeter_get_user_session(LightDMUser *user)
{
    return lightdm_user_get_session(user);
}

GList* greeter_get_users(LightDMUserList *user_list)
{
    return lightdm_user_list_get_users(user_list);
}

LightDMUser* greeter_get_user_by_name(LightDMUserList *user_list, const gchar *username)
{
    return lightdm_user_list_get_user_by_name(user_list, username);
}

gint greeter_get_user_count(LightDMUserList *user_list)
{
    return lightdm_user_list_get_length(user_list);
}

/* POWER */

gboolean greeter_get_can_suspend()
{
    return lightdm_get_can_suspend();
}

gboolean greeter_get_can_hibernate()
{
    return lightdm_get_can_hibernate();
}

gboolean greeter_get_can_restart()
{
    return lightdm_get_can_restart();
}

gboolean greeter_get_can_shutdown()
{
    return lightdm_get_can_shutdown();
}

gboolean greeter_suspend()
{
    return lightdm_suspend(NULL);
}

gboolean greeter_hibernate()
{
    return lightdm_hibernate(NULL);
}

gboolean greeter_restart()
{
    return lightdm_restart(NULL);
}

gboolean greeter_shutdown()
{
    return lightdm_shutdown(NULL);
}


int main(int argc, char **argv)
{
    GMainLoop *main_loop;
    LightDMGreeter *greeter;
    main_loop = g_main_loop_new ();
    greeter = lightdm_greeter_new ();

    g_object_connect (greeter, "show-prompt", G_CALLBACK (show_prompt_cb), NULL);
    g_object_connect (greeter, "authentication-complete", G_CALLBACK (authentication_complete_cb), NULL);
    // Connect to LightDM daemon
    if (!lightdm_greeter_connect_sync (greeter, NULL))
        return EXIT_FAILURE;
    // Start authentication
    lightdm_greeter_authenticate (greeter, NULL);

    g_main_loop_run (main_loop);

    return 0;
}

static void show_prompt_cb(LightDMGreeter *greeter, const char *text, LightDMPromptType type)
{
    // Show the user the message and prompt for some response
    gchar *secret = prompt_user (text, type);
    // Give the result to the user
    lightdm_greeter_respond (greeter, response);
}

static void authentication_complete_cb(LightDMGreeter *greeter)
{
    // Start the session
    if (!lightdm_greeter_get_is_authenticated (greeter) ||
        !lightdm_greeter_start_session_sync (greeter, NULL))
    {
        // Failed authentication, try again
        lightdm_greeter_authenticate (greeter, NULL);
    }
}
