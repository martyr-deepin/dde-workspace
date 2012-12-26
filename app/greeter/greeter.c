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

#include <gtk/gtk.h>
#include <lightdm.h>
#include "jsextension.h"
#include "dwebview.h"
#include "i18n.h"

#define GREETER_HTML_PATH "file://"RESOURCE_DIR"/greeter/index.html"

GtkWidget* container = NULL;

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
/* return list of session name */
JS_EXPORT_API
ArrayContainer greeter_get_sessions()
{
    GList *sessions = NULL;
    const gchar *name = NULL;
    LightDMSession *session = NULL;
    GPtrArray *names = g_ptr_array_new();

    sessions = lightdm_get_sessions();
    g_assert(sessions);

    for(int i=0; i < g_list_length(sessions); i++){
        session = (LightDMSession *)g_list_nth_data(sessions, i);
        g_assert(session);

        name = lightdm_session_get_name(session);
        g_ptr_array_add(names, (gpointer)g_strdup(name));

    }
    g_object_unref(session);
    g_list_free(sessions);

    ArrayContainer ac;
    ac.num = names->len;
    ac.data = names->pdata;
    g_ptr_array_free(names, FALSE);

    return ac;
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
JS_EXPORT_API
gboolean greeter_get_can_suspend()
{
    return lightdm_get_can_suspend();
}

JS_EXPORT_API
gboolean greeter_get_can_hibernate()
{
    return lightdm_get_can_hibernate();
}

JS_EXPORT_API
gboolean greeter_get_can_restart()
{
    return lightdm_get_can_restart();
}

JS_EXPORT_API
gboolean greeter_get_can_shutdown()
{
    return lightdm_get_can_shutdown();
}

JS_EXPORT_API
gboolean greeter_suspend()
{
    return lightdm_suspend(NULL);
}

JS_EXPORT_API
gboolean greeter_hibernate()
{
    return lightdm_hibernate(NULL);
}

JS_EXPORT_API
gboolean greeter_restart()
{
    return lightdm_restart(NULL);
}

JS_EXPORT_API
gboolean greeter_shutdown()
{
    return lightdm_shutdown(NULL);
}


int main(int argc, char **argv)
{
    init_i18n();
    gtk_init(&argc, &argv);

    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);
    gtk_window_fullscreen(GTK_WINDOW(container));

    GtkWidget *webview = d_webview_new_with_uri(GREETER_HTML_PATH);

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));

    g_signal_connect (container , "destroy", G_CALLBACK (gtk_main_quit), NULL);

    gtk_widget_realize(container);

    gtk_widget_show_all(container);

    monitor_resource_file("greeter", webview);
    gtk_main();
    return 0;
}
