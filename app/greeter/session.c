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

#include "session.h"

gboolean 
is_session_valid(const gchar *session)
{
    gboolean ret = FALSE;
    if((session == NULL)){
	    return ret;
    }

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

static LightDMSession* 
find_session_by_key(const gchar *key)
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

const gchar* 
get_first_session()
{
    const gchar *key = NULL;
    GList *sessions = NULL;
    LightDMSession *session = NULL;

    sessions = lightdm_get_sessions();
    g_assert(sessions);

    session = (LightDMSession *)g_list_nth_data(sessions, 0);
    g_assert(session);

    key = lightdm_session_get_key(session);

    return key;
}


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
        icon = "xfce.png";

    }else if(g_str_has_prefix(session, "cde")){
        icon = "cde.png";

    }else{
        icon = "unknown.png";
    }

    return icon;
}
