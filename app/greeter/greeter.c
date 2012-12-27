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
#include <glib.h>

#define XSESSIONS_DIR "/usr/share/xsessions/"
#define GREETER_HTML_PATH "file://"RESOURCE_DIR"/greeter/index.html"

GtkWidget* container = NULL;

LightDMGreeter *greeter = NULL;

static const gchar* get_first_user();
static const gchar* get_first_session();
static LightDMSession* find_session_by_key(const gchar *key);

/* GREETER */

JS_EXPORT_API
const gchar* greeter_get_default_user()
{
    const gchar* user = NULL;

    user = g_strdup(lightdm_greeter_get_select_user_hint(greeter));
    if(user == NULL){
        user = get_first_user();
    }
    return user;
}

JS_EXPORT_API
const gchar* greeter_get_default_session()
{
    const gchar* session = NULL;

    session = g_strdup(lightdm_greeter_get_default_session_hint(greeter));
    if(session == NULL){
        session = get_first_session();
    }

    return session;
}

gboolean greeter_connect_lightdm(LightDMGreeter *greeter)
{
    return lightdm_greeter_connect_sync(greeter, NULL);
}

gboolean greeter_support_guest(LightDMGreeter *greeter)
{
    return lightdm_greeter_get_has_guest_account_hint(greeter);
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

/* get session icon from xsession desktop file */
static const gchar* get_icon_path(const gchar *key)
{
    const gchar *icon_path = NULL, *file_path = NULL, *domain = NULL;
    GKeyFile *key_file = NULL;
    LightDMSession *session = NULL;

    file_path = g_strdup_printf("%s%s%s", XSESSIONS_DIR, key, ".desktop");

    if(!(g_file_test(file_path, G_FILE_TEST_EXISTS))){
        return NULL;
    }

    key_file = g_key_file_new();

    if(!(g_key_file_load_from_file(key_file, file_path, G_KEY_FILE_NONE, NULL))){
        g_key_file_free(key_file);
        return NULL;
    }

    if (g_key_file_get_boolean (key_file, G_KEY_FILE_DESKTOP_GROUP, G_KEY_FILE_DESKTOP_KEY_NO_DISPLAY, NULL) ||
        g_key_file_get_boolean (key_file, G_KEY_FILE_DESKTOP_GROUP, G_KEY_FILE_DESKTOP_KEY_HIDDEN, NULL)){
        g_key_file_free(key_file);
        return NULL;
    }

#ifdef G_KEY_FILE_DESKTOP_KEY_GETTEXT_DOMAIN
    domain = g_key_file_get_string (key_file, G_KEY_FILE_DESKTOP_GROUP, G_KEY_FILE_DESKTOP_KEY_GETTEXT_DOMAIN, NULL);
#else
    domain = g_key_file_get_string (key_file, G_KEY_FILE_DESKTOP_GROUP, "X-GNOME-Gettext-Domain", NULL);
#endif

    icon_path = g_key_file_get_locale_string(key_file, G_KEY_FILE_DESKTOP_GROUP, G_KEY_FILE_DESKTOP_KEY_ICON, domain, NULL);

    g_key_file_free(key_file);
    return icon_path;
}

static LightDMSession* find_session_by_key(const gchar *key)
{
    LightDMSession *session = NULL;
    GList *sessions = NULL;
    const gchar *session_key = NULL;

    sessions = lightdm_get_sessions();
    g_assert(sessions);

    for(int i = 0; i < g_list_length(sessions); i++){
        session = (LightDMSession *)g_list_nth_data(sessions, i);
        g_assert(session);
        session_key = lightdm_session_get_key(session);

        if((g_strcmp0(key, g_strdup(session_key))) == 0){
            return session;
        }else{
            continue;
        }
    }

    return NULL;
}

/* return list of session key */
JS_EXPORT_API
ArrayContainer greeter_get_sessions()
{
    GList *sessions = NULL;
    const gchar *key = NULL;
    LightDMSession *session = NULL;
    GPtrArray *keys = g_ptr_array_new();

    sessions = lightdm_get_sessions();
    g_assert(sessions);

    for(int i = 0; i < g_list_length(sessions); i++){
        session = (LightDMSession *)g_list_nth_data(sessions, i);
        g_assert(session);
        key = lightdm_session_get_key(session);
        g_ptr_array_add(keys, g_strdup(key));
    }

    ArrayContainer sessions_ac;
    sessions_ac.num = keys->len;
    sessions_ac.data = keys->pdata;
    g_ptr_array_free(keys, FALSE);

    return sessions_ac;
}

static const gchar* get_first_session()
{
    const gchar* name = NULL;
    GList *sessions = NULL;
    const gchar *key = NULL;
    LightDMSession *session = NULL;
    GPtrArray *keys = g_ptr_array_new();

    sessions = lightdm_get_sessions();
    g_assert(sessions);

    session = (LightDMSession *)g_list_nth_data(sessions, 0);
    g_assert(session);

    name = g_strdup(lightdm_session_get_key(session));

    return name;
}

/* get session name according to session key */
JS_EXPORT_API
const gchar* greeter_get_session_name(const gchar *key)
{
    const gchar *name = NULL;
    LightDMSession *session = NULL;

    session = find_session_by_key(key);
    g_assert(session);

    if(session == NULL){
        name = g_strdup(key);
    }else{
        name = g_strdup(lightdm_session_get_comment(session));
    }

    return name;
}

/* get session comment according to session key */
JS_EXPORT_API
const gchar* greeter_get_session_comment(const gchar *key)
{
    const gchar *comment = NULL;
    LightDMSession *session = NULL;

    session = find_session_by_key(key);
    g_assert(session);

    if(session == NULL){
        comment = g_strdup(key);
    }else{
        comment = g_strdup(lightdm_session_get_comment(session));
    }

    return comment;
}

/* get session icon according to session key */
JS_EXPORT_API
const gchar* greeter_get_session_icon(const gchar *key)
{
    return "icon";
}

/* USER  */
JS_EXPORT_API
ArrayContainer greeter_get_users()
{
    LightDMUserList *user_list = NULL;
    GList *users = NULL;
    LightDMUser *user = NULL;
    const gchar *name = NULL;
    GPtrArray *names = g_ptr_array_new();

    user_list = lightdm_user_list_get_instance();
    g_assert(user_list);

    users = lightdm_user_list_get_users(user_list);
    g_assert(users);

    for(int i = 0; i < g_list_length(users); i++){
        user = (LightDMUser *)g_list_nth_data(users, i);
        g_assert(user);
        name = lightdm_user_get_name(user);
        g_ptr_array_add(names, g_strdup(name));
    }

    ArrayContainer users_ac;
    users_ac.num = names->len;
    users_ac.data = names->pdata;
    g_ptr_array_free(names, FALSE);

    return users_ac;
}

static const gchar* get_first_user()
{
    LightDMUserList *user_list = NULL;
    GList *users = NULL;
    LightDMUser *user = NULL;
    const gchar *name = NULL;
    GPtrArray *names = g_ptr_array_new();

    user_list = lightdm_user_list_get_instance();
    g_assert(user_list);

    users = lightdm_user_list_get_users(user_list);
    g_assert(users);

    user = (LightDMUser *)g_list_nth_data(users, 0);
    g_assert(user);

    name = g_strdup(lightdm_user_get_name(user));

    return name;
}

JS_EXPORT_API
const gchar* greeter_get_user_image(const gchar* name)
{
    const gchar* image = NULL;
    LightDMUserList *user_list = NULL;
    LightDMUser *user = NULL;

    user_list = lightdm_user_list_get_instance();
    g_assert(user_list);

    user = lightdm_user_list_get_user_by_name(user_list, name);
    g_assert(user);

    image = g_strdup(lightdm_user_get_image(user)); 

    return image;
}

JS_EXPORT_API
const gchar* greeter_get_user_session(const gchar* name)
{
    const gchar* session = NULL;
    LightDMUserList *user_list = NULL;
    LightDMUser *user = NULL;

    user_list = lightdm_user_list_get_instance();
    g_assert(user_list);

    user = lightdm_user_list_get_user_by_name(user_list, name);
    g_assert(user);

    session = g_strdup(lightdm_user_get_session(user)); 

    return session;
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

    greeter = lightdm_greeter_new();
    g_assert(greeter);

    GtkWidget *webview = d_webview_new_with_uri(GREETER_HTML_PATH);

    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));

    g_signal_connect (container , "destroy", G_CALLBACK (gtk_main_quit), NULL);

    gtk_widget_realize(container);

    gtk_widget_show_all(container);

    monitor_resource_file("greeter", webview);
    gtk_main();
    return 0;
}
