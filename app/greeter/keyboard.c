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

#include <gtk/gtk.h>
#include "jsextension.h"
#include "keyboard.h"

#define USER_INI_PATH "/var/lib/greeter/user.ini"

GList* g_layouts = NULL;
gchar** layouts = NULL;

GKeyFile* key_file = NULL;
char** user_list = NULL;

LightDMLayout*
find_layout_by_des(gchar *des)
{
    LightDMLayout *ret = NULL;
    guint i;

    if (g_layouts == NULL) {
        g_layouts = lightdm_get_layouts ();
    }

    for (i = 0; i < g_list_length (g_layouts); i++) {
        LightDMLayout *layout = (LightDMLayout *) g_list_nth_data (g_layouts, i);

        if (layout != NULL) {
            const gchar *layout_des = g_strdup (lightdm_layout_get_description (layout));
            if (g_strcmp0 (des, layout_des) == 0) {
                ret = layout;

            } else {
                continue;
            }
        } else {
            continue;
        }
    }

    return ret;
}

LightDMLayout*
find_layout_by_name(gchar *name)
{
    LightDMLayout *ret = NULL;
    guint i;

    if (g_layouts == NULL) {
        g_layouts = lightdm_get_layouts ();
    }

    for (i = 0; i < g_list_length (g_layouts); i++) {
        LightDMLayout *layout = (LightDMLayout *) g_list_nth_data (g_layouts, i);

        if (layout != NULL) {
            const gchar *layout_name = g_strdup (lightdm_layout_get_name (layout));
            if (g_strcmp0 (name, layout_name) == 0) {
                ret = layout;

            } else {
                continue;
            }
        } else {
            continue;
        }
    }

    return ret;
}


JS_EXPORT_API
gchar* greeter_get_current_layout ()
{
    LightDMLayout *layout  = lightdm_get_layout();
    gchar *des = g_strdup (lightdm_layout_get_description (layout));
    return des;
}

JS_EXPORT_API
void greeter_set_layout (gchar* des)
{
    LightDMLayout *layout = find_layout_by_des(des);
    lightdm_set_layout(layout);
}

JS_EXPORT_API
const gchar* greeter_get_short_description (gchar* name)
{
    LightDMLayout *layout = find_layout_by_name(name);
    const gchar* des = lightdm_layout_get_short_description(layout);
    return des;
}

JS_EXPORT_API
const gchar* greeter_get_description (gchar* name)
{
    LightDMLayout *layout = find_layout_by_name(name);
    const gchar* des = lightdm_layout_get_description(layout);
    return des;
}



char** get_user_groups()
{
   key_file = g_key_file_new();
   gboolean load = g_key_file_load_from_file (key_file,USER_INI_PATH , G_KEY_FILE_NONE, NULL);
   gsize len;
   user_list = g_key_file_get_groups(key_file,&len);
   g_message("get_user_groups length:%d,load:%d",(int)len,load);
   return user_list;
}

JSObjectRef export_layouts (gchar** layouts_list)
{
    JSObjectRef array = json_array_create ();
    guint i;
    guint len = g_strv_length(layouts_list);
    g_message("layouts_list len:%d",len);
    for (i = 0; i < len; i++) {
        gchar* dest = NULL;
        g_utf8_strncpy(dest,layouts_list[i],(gsize)(g_utf8_strlen(layouts_list[i],0)-1));
        g_message("keyboard layout:%d:=========%s===========",i,dest);
        LightDMLayout *layout = find_layout_by_name(dest);
        const gchar* name = g_strdup(lightdm_layout_get_description(layout));
        json_array_insert (array, i, jsvalue_from_cstr (get_global_context (), g_strdup (name)));
        g_free(dest);
    }
    return array;
}

JS_EXPORT_API
JSObjectRef greeter_get_user_config_list()
{
    if(user_list == NULL){
       get_user_groups();
    }
    JSObjectRef array = json_array_create();
    guint len = g_strv_length(user_list);
    for (guint i = 0;i < len; i++)
    {
        g_message("list:%d:%s",i,user_list[i]);
        gchar* current_layout = g_key_file_get_string(key_file,user_list[i],"KeyboardLayout",NULL);
        layouts = g_key_file_get_string_list(key_file,user_list[i],"KeyboardLayoutList",NULL,NULL);
        gchar* greeter_theme = g_key_file_get_string(key_file,user_list[i],"GreeterTheme",NULL);



   JSObjectRef json = json_create();
   json_append_string(json,"username",user_list[i]);
   json_append_string(json,"current_layout",current_layout);
   json_append_string(json,"greeter-theme",greeter_theme);
   g_free(current_layout);
   g_free(greeter_theme);
   json_array_insert(array,i,json);
   
   JSObjectRef obj = export_layouts(layouts);
   json_array_insert(array,i,obj);
   }
   g_strfreev(user_list);
   return array;
}



JS_EXPORT_API
JSObjectRef greeter_lightdm_get_layouts ()
{
    JSObjectRef array = json_array_create ();
    guint i;

    if (g_layouts == NULL) {
        g_layouts = lightdm_get_layouts ();
    }

    for (i = 0; i < g_list_length (g_layouts); i++) {
        LightDMLayout *layout = (LightDMLayout *) g_list_nth_data (g_layouts, i);

        if (layout != NULL) {
            const gchar *name = g_strdup (lightdm_layout_get_name (layout));
            json_array_insert (array, i, jsvalue_from_cstr (get_global_context (), g_strdup (name)));
        } else {
            continue;
        }
    }
    return array;
}


