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
#include "utils.h"
#include <glib.h>
#include <stdlib.h>

#define XSESSIONS_DIR "/usr/share/xsessions/"
#define GREETER_HTML_PATH "file://"RESOURCE_DIR"/greeter/index.html"

GtkWidget* container = NULL;
GtkWidget* webview = NULL;
LightDMGreeter *greeter = NULL;
static gboolean cancelling = FALSE, prompted = FALSE;
gchar *selected_user = NULL, *selected_session = NULL;

static const gchar* get_first_user();
static const gchar* get_first_session();
static LightDMSession* find_session_by_key(const gchar *key);
static void start_session(const gchar *session);

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

static gchar* get_selected_user()
{
    if(selected_user != NULL){
        return selected_user;
    }else{
        return g_strdup(greeter_get_default_user());
    }
}

static gchar* get_selected_session()
{
    if(selected_session != NULL){
        return selected_session;
    }else{
        return g_strdup(greeter_get_default_session());
    }
}

JS_EXPORT_API
void greeter_set_selected_user(const gchar *username)
{
    selected_user = g_strdup(username);
}

JS_EXPORT_API
void greeter_set_selected_session(const gchar *session)
{
    selected_session = g_strdup(session);
}

JS_EXPORT_API
gboolean greeter_in_authentication()
{
    return lightdm_greeter_get_in_authentication(greeter);
}

JS_EXPORT_API
void greeter_start_authentication(const gchar *username)
{
    cancelling = FALSE;
    prompted = FALSE;

    js_post_message_simply("status", "{\"status\":\"auth user %s\"}", username);

    if(g_strcmp0(username, g_strdup("*other")) == 0){
        lightdm_greeter_authenticate(greeter, NULL);

    }else if(g_strcmp0(username, g_strdup("*guest")) == 0){
        lightdm_greeter_authenticate_as_guest(greeter);

    }else{
        lightdm_greeter_authenticate(greeter, username);
    }
}

JS_EXPORT_API
void greeter_cancel_authentication()
{
    cancelling = FALSE;
    if(lightdm_greeter_get_in_authentication(greeter)){
        cancelling = TRUE;
        lightdm_greeter_cancel_authentication(greeter);
        return ;
    }

    if(lightdm_greeter_get_hide_users_hint(greeter)){
        greeter_start_authentication(g_strdup("*other"));
    }
}

JS_EXPORT_API
void greeter_login_clicked(const gchar *password)
{
    js_post_message_simply("status", "{\"status\":\"%s\"}", "login clicked");

    selected_user = get_selected_user();
    selected_session = get_selected_session();

    if(lightdm_greeter_get_is_authenticated(greeter)){
        js_post_message_simply("status", "{\"status\":\"%s\"}", "login clicked, start_session");
        start_session(selected_session);

    }else if(lightdm_greeter_get_in_authentication(greeter)){
        js_post_message_simply("status", "{\"status\":\"%s\"}", "login clicked, respond");
        lightdm_greeter_respond(greeter, password);

    }else{
        js_post_message_simply("status", "{\"status\":\"%s\"}", "login clicked, start auth");
        greeter_start_authentication(selected_user);
    }
}

static void start_session(const gchar *session)
{
    js_post_message_simply("status", "{\"status\":\"start session %s\"}", session);

    if(!lightdm_greeter_start_session_sync(greeter, session, NULL)){
        js_post_message_simply("status", "{\"status\":\"%s\"}", "start session failed");
        greeter_start_authentication(g_strdup(get_selected_user()));
    }
}

static void show_prompt_cb(LightDMGreeter *greeter, const gchar *text, LightDMPromptType type)
{
    prompted = TRUE;
    js_post_message_simply("status", "{\"status\":\"%s\"}", "show prompt cb");
}

static void authentication_complete_cb(LightDMGreeter *greeter)
{
    js_post_message_simply("status", "{\"status\":\"%s\"}", "authentication complete cb");

    if(cancelling){
        greeter_cancel_authentication();
    }

    if(lightdm_greeter_get_is_authenticated(greeter)){
        if(prompted){
            js_post_message_simply("status", "{\"status\":\"%s\"}", "auth complete, start session");
            start_session(g_strdup(get_selected_session()));
        }
    }else{
        if(prompted){
            js_post_message_simply("status", "{\"status\":\"%s\"}", "auth complete, re start auth");
            greeter_start_authentication(get_selected_user());
        }
    }
}

JS_EXPORT_API
gboolean greeter_is_hide_users()
{
    return lightdm_greeter_get_hide_users_hint(greeter);
}
	
JS_EXPORT_API
gboolean greeter_support_guest()
{
    return lightdm_greeter_get_has_guest_account_hint(greeter);
}

JS_EXPORT_API
gboolean greeter_get_guest_default()
{
    return lightdm_greeter_get_select_guest_hint(greeter);
}

JS_EXPORT_API
const gchar* greeter_get_autologin_user()
{
    return lightdm_greeter_get_autologin_user_hint(greeter);
}

JS_EXPORT_API
gboolean greeter_get_guest_autologin()
{
    return lightdm_greeter_get_autologin_guest_hint(greeter);
}

JS_EXPORT_API
void greeter_authenticate_guest()
{
    lightdm_greeter_authenticate_as_guest(greeter);
}

JS_EXPORT_API
gint greeter_get_autologin_timeout()
{
    return lightdm_greeter_get_autologin_timeout_hint(greeter);
}

JS_EXPORT_API
void greeter_cancel_autologin()
{
    lightdm_greeter_cancel_autologin(greeter);
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
    const gchar* icon = NULL;
    const gchar* session = NULL;

    session = g_strdup(g_ascii_strdown(key, -1));
    g_assert(session);

    if(g_str_has_prefix(session, "gnome")){
        icon = g_strdup("gnome.png");

    }else if(g_str_has_prefix(session, "deepin")){
        icon = g_strdup("deepin.png");

    }else if(g_str_has_prefix(session, "kde")){
        icon = g_strdup("kde.png");

    }else if(g_str_has_prefix(session, "ubuntu")){
        icon = g_strdup("ubuntu.png");

    }else if(g_str_has_prefix(session, "xfce")){
        icon = g_strdup("ubuntu.png");

    }else{
        icon = g_strdup("unknown.png");
    }

    return icon;
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
    if(session == NULL){
        session = get_first_session();
    }

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
gboolean greeter_run_suspend()
{
    js_post_message_simply("power", "{\"status\":\"%s\"}", "suspend clicked");
    js_post_message_simply("power", "{\"status\":\"%s\"}", getuid());
    return lightdm_suspend(NULL);
}

JS_EXPORT_API
gboolean greeter_run_hibernate()
{
    js_post_message_simply("power", "{\"status\":\"%s\"}", "hibernate clicked");
    js_post_message_simply("power", "{\"status\":\"%s\"}", getuid());
    return lightdm_hibernate(NULL);
}

JS_EXPORT_API
gboolean greeter_run_restart()
{
    js_post_message_simply("power", "{\"status\":\"%s\"}", "restart clicked");
    js_post_message_simply("power", "{\"status\":\"%s\"}", getuid());
    return lightdm_restart(NULL);
}

JS_EXPORT_API
gboolean greeter_run_shutdown()
{
    js_post_message_simply("power", "{\"status\":\"%s\"}", "shutdown clicked");
    js_post_message_simply("power", "{\"status\":\"%s\"}", getuid());
    return lightdm_shutdown(NULL);
}

static void sigterm_cb(int signum)
{
    exit(0);
}

int main(int argc, char **argv)
{
    GdkScreen *screen;
    GdkRectangle geometry;

    signal(SIGTERM, sigterm_cb);

    init_i18n();
    gtk_init(&argc, &argv);

    greeter = lightdm_greeter_new();
    g_assert(greeter);

    gdk_window_set_cursor(gdk_get_default_root_window(), gdk_cursor_new(GDK_LEFT_PTR));

    container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(container), FALSE);

    screen = gtk_window_get_screen(GTK_WINDOW(container));
    gdk_screen_get_monitor_geometry(screen, gdk_screen_get_primary_monitor(screen), &geometry);
    gtk_window_set_default_size(GTK_WINDOW(container), geometry.width, geometry.height);
	gtk_window_move(GTK_WINDOW(container), geometry.x, geometry.y);

    webview = d_webview_new_with_uri(GREETER_HTML_PATH);
    gtk_container_add(GTK_CONTAINER(container), GTK_WIDGET(webview));
    gtk_widget_realize(container);

    g_signal_connect(greeter, "show-prompt", G_CALLBACK(show_prompt_cb), NULL);  
    g_signal_connect(greeter, "authentication-complete", G_CALLBACK(authentication_complete_cb), NULL);

    gtk_widget_show_all(container);

    if(!lightdm_greeter_connect_sync(greeter, NULL)){
        exit(EXIT_FAILURE);
    }

    /* monitor_resource_file("greeter", webview); */
    gtk_main();
    return 0;
}
