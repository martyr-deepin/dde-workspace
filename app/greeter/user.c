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

#include "user.h"
#include "unistd.h"

gboolean 
is_user_valid(const gchar *username)
{
    gboolean ret = FALSE;
    if((username == NULL)){
	    return ret;
    }

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

const gchar* 
get_first_user()
{
    const gchar *name = NULL;
    LightDMUserList *user_list = NULL;
    GList *users = NULL;
    LightDMUser *user = NULL;

    user_list = lightdm_user_list_get_instance();
    g_assert(user_list);

    users = lightdm_user_list_get_users(user_list);
    g_assert(users);

    user = (LightDMUser *)g_list_nth_data(users, 0);
    g_assert(user);

    name = lightdm_user_get_name(user);

    return name;
}

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
    if(!(g_file_test(image, G_FILE_TEST_EXISTS))){
        image = "nonexists";
    }

    if(g_access(image, R_OK) != 0){
        image = "nonexists";
    }

    return image;
}

JS_EXPORT_API 
const gchar *greeter_get_user_background_dbus(const gchar* name)
{
    g_return_val_if_fail(is_user_valid(name), "nonexists");

    const gchar* background = NULL;
    GError *error = NULL;

    GDBusProxy *account_proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SYSTEM,
            G_DBUS_PROXY_FLAGS_NONE,
            NULL,
            "org.freedesktop.Accounts",
            "/org/freedesktop/Accounts",
            "org.freedesktop.Accounts",
            NULL,
            &error);

    g_assert(account_proxy != NULL);
    if (error != NULL) {
        g_warning("get user background dbus:account proxy\n");
        g_error_free (error);
     }

    GVariant *user_path_var = NULL;
    user_path_var  = g_dbus_proxy_call_sync(account_proxy,
                    "FindUserByName",
                    g_variant_new ("(s)", name),
                    G_DBUS_CALL_FLAGS_NONE,
                    -1,
                    NULL,
                    &error);

    if(error != NULL){
        g_warning ("get user background dbus:FindUserByName\n");
        g_error_free (error);
    }

    gchar *user_path = NULL;
    g_variant_get (user_path_var, "(o)", &user_path);

    if (user_path == NULL) {
        g_warning ("get user background dbus:find user by name failed\n");
        g_variant_unref (user_path_var);
        g_object_unref (account_proxy);
        return "nonexists";
    }

    g_variant_unref (user_path_var);
    g_object_unref (account_proxy);

    GDBusProxy *user_proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SYSTEM,
            G_DBUS_PROXY_FLAGS_NONE,
            NULL,
            "org.freedesktop.Accounts",
            user_path,
            "org.freedesktop.Accounts.User",
            NULL,
            &error);

    g_assert(user_proxy != NULL);
    if (error != NULL) {
        g_warning ("get user background dbus: user proxy\n");
        g_error_free (error);
    }

    GVariant *background_var = NULL;
    background_var = g_dbus_proxy_get_cached_property (user_proxy, "BackgroundFile");
    //g_variant_get (background_var, "(s)", background);
    background = g_variant_dup_string (background_var, NULL);
    if (background == NULL) {
        g_warning ("get user background dbus:background NULL\n");
        g_free (user_path);
        g_variant_unref (background_var);
        g_object_unref (user_proxy);
        return "nonexists";
    }

    g_free (user_path);
    g_variant_unref (background_var);
    g_object_unref (user_proxy);

    if(!(g_file_test(background, G_FILE_TEST_EXISTS))){
        background = "nonexists";
    }

    if(g_access(background, R_OK) != 0){
        background = "nonexists";
    }

    return background;
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
    if(!(g_file_test(background, G_FILE_TEST_EXISTS))){
        background = "nonexists";
    }

    if(g_access(background, R_OK) != 0){
        background = "nonexists";
    }

    return background;
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
