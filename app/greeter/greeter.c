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
#include <cairo-xlib.h>
#include <gdk/gdkx.h>
#include <gdk-pixbuf/gdk-pixbuf.h>
#include <lightdm.h>
#include "jsextension.h"
#include "dwebview.h"
#include "i18n.h"
#include "utils.h"
#include <glib.h>
#include <stdlib.h>

#define XSESSIONS_DIR "/usr/share/xsessions/"
#define GREETER_HTML_PATH "file://"RESOURCE_DIR"/greeter/index.html"
#define DEBUG 1

GtkWidget* container = NULL;
GtkWidget* webview = NULL;
LightDMGreeter *greeter = NULL;
GKeyFile *greeter_keyfile;
static gchar* greeter_file = NULL;
static gboolean cancelling = FALSE, prompted = FALSE;
gchar *selected_user = NULL, *selected_session = NULL;
static gint response_count = 0;

static gboolean is_user_valid(const gchar *username);
static gboolean is_session_valid(const gchar *session);
const gchar* greeter_get_default_user();
const gchar* greeter_get_default_session();
static gchar* get_selected_user();
static gchar* get_selected_session();
void greeter_set_selected_user(const gchar *username);
void greeter_set_selected_session(const gchar *session);
gboolean greeter_in_authentication();
const gchar* greeter_get_authentication_user();
gboolean greeter_is_authenticated();
void greeter_start_authentication(const gchar *username);
void greeter_cancel_authentication();
void greeter_login_clicked(const gchar *password);
static void start_session(const gchar *session);
static void show_prompt_cb(LightDMGreeter *greeter, const gchar *text, LightDMPromptType type);
static void show_message_cb(LightDMGreeter *greeter, const gchar *text, LightDMMessageType type);
static void authentication_complete_cb(LightDMGreeter *greeter);
gboolean greeter_is_hide_users();
gboolean greeter_is_support_guest();
gboolean greeter_is_guest_default();
static void autologin_timer_expired_cb(LightDMGreeter *greeter);
static LightDMSession* find_session_by_key(const gchar *key);
ArrayContainer greeter_get_sessions();
static const gchar* get_first_session();
const gchar* greeter_get_session_name(const gchar *key);
const gchar* greeter_get_session_comment(const gchar *key);
const gchar* greeter_get_session_icon(const gchar *key);
ArrayContainer greeter_get_users();
static const gchar* get_last_user();
static void set_last_user(const gchar *name);
static const gchar* get_first_user();
const gchar* greeter_get_user_image(const gchar* name);
const gchar* greeter_get_user_background(const gchar*name);
const gchar* greeter_get_user_session(const gchar* name);
gboolean greeter_get_can_suspend();
gboolean greeter_get_can_hibernate();
gboolean greeter_get_can_restart();
gboolean greeter_get_can_shutdown();
gboolean greeter_run_suspend();
gboolean greeter_run_hibernate();
gboolean greeter_run_restart();
gboolean greeter_run_shutdown();
static void sigterm_cb(int signum);
static cairo_surface_t * create_root_surface(GdkScreen *screen);
static void greeter_update_background();

/* GREETER */
static gboolean is_user_valid(const gchar *username)
{
    gboolean ret = FALSE;
    if((username == NULL) || (username == ""))
	return ret;

    LightDMUserList *user_list = NULL;
    GList *users = NULL;
    LightDMUser *user = NULL;
    const gchar *name = NULL;

    user_list = lightdm_user_list_get_instance();
    g_assert(user_list);

    users = lightdm_user_list_get_users(user_list);
    g_assert(users);

    for(int i = 0; i < g_list_length(users); i++){
        user = (LightDMUser *)g_list_nth_data(users, i);
        g_assert(user);
        name = lightdm_user_get_name(user);
        if(g_strcmp0(name, username) == 0){
            ret = TRUE;
            break;
        }else{
            continue;
        }
    }

    return ret;
}

static gboolean is_session_valid(const gchar *session)
{
    gboolean ret = FALSE;
    if((session == NULL) || (session == ""))
	return ret;

    GList *sessions = NULL;
    LightDMSession *psession = NULL;
    const gchar* key = NULL;

    sessions = lightdm_get_sessions();
    g_assert(sessions);

    for(int i = 0; i < g_list_length(sessions); i++){
        psession = (LightDMSession *)g_list_nth_data(sessions, i);
        g_assert(psession);

        key = lightdm_session_get_key(psession);
        if(g_strcmp0(session, key) == 0){
            ret = TRUE;
            break;
        }else{
            continue;   
        }
    }

    return ret;
}

JS_EXPORT_API
const gchar* greeter_get_default_user()
{
    const gchar* user = NULL;

    user = get_last_user();
    js_post_message_simply("status", "{\"status\":\"last_user-%s\"}", user);

    if(user == NULL){
        user = lightdm_greeter_get_select_user_hint(greeter);
    }
    if(user != NULL){
        if(is_user_valid(user)){
            return user; 
        }else{
            return get_first_user();
        }
    }else{
        return get_first_user();
    }
}

JS_EXPORT_API
const gchar* greeter_get_default_session()
{
    const gchar* session = NULL;

    session = lightdm_greeter_get_default_session_hint(greeter);
    if(session != NULL){
        if(is_session_valid(session)){
            return session; 
        }else{
            return get_first_session();
        }
    }else{
        return get_first_session();
    }
}

static gchar* get_selected_user()
{
    if(selected_user != NULL){
        return selected_user;
    }else{
        greeter_set_selected_user(greeter_get_default_user());
        return selected_user;
    }
}

static gchar* get_selected_session()
{
    if(selected_session != NULL){
        return selected_session;
    }else{
        greeter_set_selected_session(greeter_get_default_session());
#ifdef DEBUG
        js_post_message_simply("status", "{\"status\":\"set_selected_session-%s\"}", selected_session);
#endif
        return selected_session;
    }
}

JS_EXPORT_API
void greeter_set_selected_user(const gchar *username)
{
    g_return_if_fail(username != NULL);

    if(selected_user != NULL){
        g_free(selected_user);
        selected_user = NULL;
    }
    selected_user = g_strdup(username);
}

JS_EXPORT_API
void greeter_set_selected_session(const gchar *session)
{
    g_return_if_fail(session != NULL);

    if(selected_session != NULL){
        g_free(selected_session);
        selected_session = NULL;
    }
    selected_session = g_strdup(session);
#ifdef DEBUG
    js_post_message_simply("status", "{\"status\":\"set_selected_session-%s\"}", selected_session);
#endif
}

JS_EXPORT_API
gboolean greeter_in_authentication()
{
    return lightdm_greeter_get_in_authentication(greeter);
}

JS_EXPORT_API
const gchar* greeter_get_authentication_user()
{
    return lightdm_greeter_get_authentication_user(greeter);
}

JS_EXPORT_API
gboolean greeter_is_authenticated()
{
    return lightdm_greeter_get_is_authenticated(greeter);
}

JS_EXPORT_API
void greeter_start_authentication(const gchar *username)
{
    cancelling = FALSE;
    prompted = FALSE;
#ifdef DEBUG
    js_post_message_simply("status", "{\"status\":\"auth user %s\"}", username);
#endif
    if(g_strcmp0(username, "*other") == 0){
        lightdm_greeter_authenticate(greeter, NULL);

    }else if(g_strcmp0(username, "guest") == 0){
        lightdm_greeter_authenticate_as_guest(greeter);

    }else{
        lightdm_greeter_authenticate(greeter, username);
    }
}

JS_EXPORT_API
void greeter_cancel_authentication()
{
    cancelling = FALSE;
    response_count = 0;
    if(lightdm_greeter_get_in_authentication(greeter)){
        cancelling = TRUE;
        lightdm_greeter_cancel_authentication(greeter);
        return ;
    }

    if(lightdm_greeter_get_hide_users_hint(greeter)){
        greeter_start_authentication("*other");
    }
}

JS_EXPORT_API
void greeter_login_clicked(const gchar *password)
{
#ifdef DEBUG
    js_post_message_simply("status", "{\"status\":\"%s\"}", "login clicked");
#endif
    selected_user = get_selected_user();
    selected_session = get_selected_session();

    if(lightdm_greeter_get_is_authenticated(greeter)){
#ifdef DEBUG
        js_post_message_simply("status", "{\"status\":\"%s\"}", "login clicked, start_session");
#endif
        start_session(selected_session);

    }else if(lightdm_greeter_get_in_authentication(greeter)){
#ifdef DEBUG
        js_post_message_simply("status", "{\"status\":\"%s\"}", "login clicked, respond");
#endif
        lightdm_greeter_respond(greeter, password);
        response_count = response_count + 1;

    }else{
#ifdef DEBUG
        js_post_message_simply("status", "{\"status\":\"%s\"}", "login clicked, start auth");
#endif
        greeter_start_authentication(selected_user);
    }
}

static void start_session(const gchar *session)
{
    g_return_if_fail(is_session_valid(session));

    set_last_user(get_selected_user());
    greeter_update_background();

#ifdef DEBUG
    js_post_message_simply("status", "{\"status\":\"start session %s\"}", session);
#endif
    if(!lightdm_greeter_start_session_sync(greeter, session, NULL)){
#ifdef DEBUG
        js_post_message_simply("status", "{\"status\":\"%s\"}", "start session failed");
#endif
        greeter_start_authentication(get_selected_user());
    }else{
        g_free(greeter_file);
        greeter_file = NULL;
        g_key_file_free(greeter_keyfile);
        g_free(selected_user);
        selected_user = NULL;
        g_free(selected_session);
        selected_session = NULL;
    }
}

static void show_prompt_cb(LightDMGreeter *greeter, const gchar *text, LightDMPromptType type)
{
    prompted = TRUE;
    if(response_count == 1){
        js_post_message_simply("prompt", "{\"status\":\"%s\"}", "expect response");
    }
#ifdef DEBUG
    js_post_message_simply("status", "{\"status\":\"%s\"}", "show prompt cb");
#endif
}

static void show_message_cb(LightDMGreeter *greeter, const gchar *text, LightDMMessageType type)
{
    if(type == LIGHTDM_MESSAGE_TYPE_ERROR){
        js_post_message_simply("message", "{\"error\":\"%s\"}", text);
    }
}

static void authentication_complete_cb(LightDMGreeter *greeter)
{
#ifdef DEBUG
    js_post_message_simply("status", "{\"status\":\"%s\"}", "authentication complete cb");
#endif

    if(cancelling){
        greeter_cancel_authentication();
        return ;
    }

    if(lightdm_greeter_get_is_authenticated(greeter)){
        if(prompted){
#ifdef DEBUG
            js_post_message_simply("status", "{\"status\":\"%s\"}", "auth complete, start session");
#endif
            start_session(get_selected_session());
        }
    }else{
        if(prompted){
#ifdef DEBUG
            js_post_message_simply("status", "{\"status\":\"%s\"}", "auth complete, re start auth");
#endif
            js_post_message_simply("auth", "{\"error\":\"%s\"}", _("Invalid Username/Password"));
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
gboolean greeter_is_support_guest()
{
    return lightdm_greeter_get_has_guest_account_hint(greeter);
}

JS_EXPORT_API
gboolean greeter_is_guest_default()
{
    return lightdm_greeter_get_select_guest_hint(greeter);
}

static void autologin_timer_expired_cb(LightDMGreeter *greeter)
{
    if(lightdm_greeter_get_autologin_guest_hint(greeter)){
        greeter_start_authentication("guest");

    }else if(lightdm_greeter_get_autologin_user_hint(greeter)){
        const gchar *username = lightdm_greeter_get_autologin_user_hint(greeter);
        if(is_user_valid(username)){
            greeter_start_authentication(username);
        }else{
            greeter_start_authentication(greeter_get_default_user());
        }
    }
}

/* SESSION */
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

        if((g_strcmp0(key, session_key)) == 0){
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

    name = lightdm_session_get_key(session);

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
        name = key;
    }else{
        name = lightdm_session_get_name(session);
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
        comment = key;
    }else{
        comment = lightdm_session_get_comment(session);
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
        icon = "gnome.png";

    }else if(g_str_has_prefix(session, "deepin")){
        icon = "deepin.png";

    }else if(g_str_has_prefix(session, "kde")){
        icon = "kde.png";

    }else if(g_str_has_prefix(session, "ubuntu")){
        icon = "ubuntu.png";

    }else if(g_str_has_prefix(session, "xfce")){
        icon = "ubuntu.png";

    }else{
        icon = "unknown.png";
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

    name = lightdm_user_get_name(user);

    return name;
}

static const gchar* get_last_user()
{
    return g_key_file_get_value(greeter_keyfile, "deepin-greeter", "last-user", NULL);
}

static void set_last_user(const gchar* name){
    gchar *data;
    gsize length;
    g_return_if_fail(name);

    g_key_file_set_value(greeter_keyfile, "deepin-greeter", "last-user", name);
    data = g_key_file_to_data(greeter_keyfile, &length, NULL);
    g_file_set_contents(greeter_file, data, length, NULL);
    g_free(data);
}

JS_EXPORT_API
const gchar* greeter_get_user_image(const gchar* name)
{
    g_return_val_if_fail(is_user_valid(name), "nonexists");

    const gchar* image = NULL;
    LightDMUserList *user_list = NULL;
    LightDMUser *user = NULL;

    user_list = lightdm_user_list_get_instance();
    g_assert(user_list);

    user = lightdm_user_list_get_user_by_name(user_list, name);
    g_assert(user);

    image = lightdm_user_get_image(user);
    if(g_file_test(image, G_FILE_TEST_EXISTS)){
        return image;
    }else{
        return "nonexists";
    }
}

JS_EXPORT_API
const gchar* greeter_get_user_background(const gchar* name)
{
    g_return_val_if_fail(is_user_valid(name), "nonexists");

    const gchar* background = NULL;
    LightDMUserList *user_list = NULL;
    LightDMUser *user = NULL;

    user_list = lightdm_user_list_get_instance();
    g_assert(user_list);

    user = lightdm_user_list_get_user_by_name(user_list, name);
    g_assert(user);

    background = lightdm_user_get_background(user);
    if((g_file_test(background, G_FILE_TEST_EXISTS))){
        return background;
    }
	return "nonexists";
}

JS_EXPORT_API
const gchar* greeter_get_user_session(const gchar* name)
{
    g_return_val_if_fail(is_user_valid(name), "nonexists");

    const gchar* session = NULL;
    LightDMUserList *user_list = NULL;
    LightDMUser *user = NULL;

    user_list = lightdm_user_list_get_instance();
    g_assert(user_list);

    user = lightdm_user_list_get_user_by_name(user_list, name);
    g_assert(user);

    session = lightdm_user_get_session(user);
    if(session == NULL){
	session = "nonexists";
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
#ifdef DEBUG
    js_post_message_simply("power", "{\"status\":\"%s\"}", "suspend clicked");
    js_post_message_simply("power", "{\"status\":\"%s\"}", getuid());
#endif
    return lightdm_suspend(NULL);
}

JS_EXPORT_API
gboolean greeter_run_hibernate()
{
#ifdef DEBUG
    js_post_message_simply("power", "{\"status\":\"%s\"}", "hibernate clicked");
    js_post_message_simply("power", "{\"status\":\"%s\"}", getuid());
#endif
    return lightdm_hibernate(NULL);
}

JS_EXPORT_API
gboolean greeter_run_restart()
{
#ifdef DEBUG
    js_post_message_simply("power", "{\"status\":\"%s\"}", "restart clicked");
    js_post_message_simply("power", "{\"status\":\"%s\"}", getuid());
#endif
    return lightdm_restart(NULL);
}

JS_EXPORT_API
gboolean greeter_run_shutdown()
{
#ifdef DEBUG
    js_post_message_simply("power", "{\"status\":\"%s\"}", "shutdown clicked");
    js_post_message_simply("power", "{\"status\":\"%s\"}", getuid());
#endif
    return lightdm_shutdown(NULL);
}

static void sigterm_cb(int signum)
{
    exit(0);
}

static cairo_surface_t * create_root_surface (GdkScreen *screen)
{
    gint number, width, height;
    Display *display;
    Pixmap pixmap;
    cairo_surface_t *surface;

    number = gdk_screen_get_number (screen);
    width = gdk_screen_get_width (screen);
    height = gdk_screen_get_height (screen);

    /* Open a new connection so with Retain Permanent so the pixmap remains when the greeter quits */
    gdk_flush ();
    display = XOpenDisplay (gdk_display_get_name (gdk_screen_get_display (screen)));
    if (!display)
    {
        g_warning ("Failed to create root pixmap");
        return NULL;
    }
    XSetCloseDownMode (display, RetainPermanent);
    pixmap = XCreatePixmap (display, RootWindow (display, number), width, height, DefaultDepth (display, number));
    XCloseDisplay (display);

    /* Convert into a Cairo surface */
    surface = cairo_xlib_surface_create (GDK_SCREEN_XDISPLAY (screen),
                                         pixmap,
                                         GDK_VISUAL_XVISUAL (gdk_screen_get_system_visual (screen)),
                                         width, height);

    /* Use this pixmap for the background */
    XSetWindowBackgroundPixmap (GDK_SCREEN_XDISPLAY (screen),
                                RootWindow (GDK_SCREEN_XDISPLAY (screen), number),
                                cairo_xlib_surface_get_drawable (surface));


    return surface;  
}

static void greeter_update_background()
{
    GdkPixbuf *background_pixbuf = NULL;
    GdkRGBA background_color;
    GdkRectangle monitor_geometry;

    selected_user = get_selected_user();
    const gchar *bg_path = greeter_get_user_background(selected_user);
    if(g_strcmp0(bg_path, "nonexists") == 0){
        bg_path = "/usr/share/backgrounds/1440x900.jpg";
    }
    
    if (!gdk_rgba_parse (&background_color, bg_path)){
        background_pixbuf = gdk_pixbuf_new_from_file (bg_path, NULL);
        if (!background_pixbuf)
           g_warning ("Failed to load background: %s", bg_path);
    }

    for (int i = 0; i < gdk_display_get_n_screens (gdk_display_get_default ()); i++)
    {
        GdkScreen *screen;
        cairo_surface_t *surface;
        cairo_t *c;
        int monitor;

        screen = gdk_display_get_screen (gdk_display_get_default (), i);
        surface = create_root_surface (screen);
        c = cairo_create (surface);

        for (monitor = 0; monitor < gdk_screen_get_n_monitors (screen); monitor++)
        {
            gdk_screen_get_monitor_geometry (screen, monitor, &monitor_geometry);

            if (background_pixbuf)
            {
                GdkPixbuf *pixbuf = gdk_pixbuf_scale_simple (background_pixbuf, monitor_geometry.width, monitor_geometry.height, GDK_INTERP_BILINEAR);
                gdk_cairo_set_source_pixbuf (c, pixbuf, monitor_geometry.x, monitor_geometry.y);
                g_object_unref (pixbuf);
            }
            else
                gdk_cairo_set_source_rgba (c, &background_color);
            cairo_paint (c);
        }

        cairo_destroy (c);

        /* Refresh background */
        gdk_flush ();
        XClearWindow (GDK_SCREEN_XDISPLAY (screen), RootWindow (GDK_SCREEN_XDISPLAY (screen), i));
    }
    if (background_pixbuf)
        g_object_unref (background_pixbuf);
}

int main(int argc, char **argv)
{
    GdkScreen *screen;
    GdkRectangle geometry;

    signal(SIGTERM, sigterm_cb);

    init_i18n();
    gtk_init(&argc, &argv);

    gchar *greeter_dir = g_build_filename(g_get_user_cache_dir(), "lightdm", NULL);
    if(g_mkdir_with_parents(greeter_dir, 0755) < 0){
        greeter_dir = "/var/cache/lightdm";
    }
    
    greeter_file = g_build_filename(greeter_dir, "deepin-greeter", NULL);
    g_free(greeter_dir);

    greeter_keyfile = g_key_file_new();
    g_key_file_load_from_file(greeter_keyfile, greeter_file, G_KEY_FILE_NONE, NULL);

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
    g_signal_connect(greeter, "show-message", G_CALLBACK(show_message_cb), NULL);
    g_signal_connect(greeter, "authentication-complete", G_CALLBACK(authentication_complete_cb), NULL);
    g_signal_connect(greeter, "autologin-timer-expired", G_CALLBACK(autologin_timer_expired_cb), NULL);

    if(!lightdm_greeter_connect_sync(greeter, NULL)){
        exit(EXIT_FAILURE);
    }

    gtk_widget_show_all(container);

 //   monitor_resource_file("greeter", webview);
    gtk_main();
    return 0;
}
