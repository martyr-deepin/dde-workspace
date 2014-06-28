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

#include "keyboard.h"

static GList *layouts = NULL;

JS_EXPORT_API
JSObjectRef greeter_get_layouts ()
{
    JSObjectRef array = json_array_create ();

    guint i;

    if (layouts == NULL) {
        layouts = lightdm_get_layouts ();
    }

    for (i = 0; i < g_list_length (layouts); ++i) {
        LightDMLayout *layout = (LightDMLayout *) g_list_nth_data (layouts, i);

        /*gchar *name = g_strdup (lightdm_layout_get_name (layout));*/
        const gchar* name = g_strdup(lightdm_layout_get_description(layout));
        json_array_insert (array, i, jsvalue_from_cstr (get_global_context (), g_strdup (name)));
        /*g_free (name);*/
    }

    return array;
}

JS_EXPORT_API
gchar* greeter_get_current_layout ()
{
    LightDMLayout *layout  = lightdm_get_layout();
    gchar *name = g_strdup (lightdm_layout_get_description (layout));
    /*gchar *name = g_strdup (lightdm_layout_get_name (layout));*/
    return name;
}

LightDMLayout*
find_layout_by_name(gchar *name)
{
    LightDMLayout *ret = NULL;
    guint i;

    if (layouts == NULL) {
        layouts = lightdm_get_layouts ();
    }

    for (i = 0; i < g_list_length (layouts); i++) {
        LightDMLayout *layout = (LightDMLayout *) g_list_nth_data (layouts, i);

        if (layout != NULL) {
            const gchar *layout_name = g_strdup (lightdm_layout_get_description (layout));
            /*gchar *layout_name = g_strdup (lightdm_layout_get_name (layout));*/
            if (g_strcmp0 (name, layout_name) == 0) {
                ret = layout;

            } else {
                continue;
            }
            /*g_free (layout_name);*/

        } else {
            continue;
        }
    }

    return ret;
}

JS_EXPORT_API
void greeter_set_layout (gchar* name)
{
    LightDMLayout *layout = find_layout_by_name(name);
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

