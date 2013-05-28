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
#include "account.h"

gboolean is_capslock_on ()
{
    gboolean capslock_flag = FALSE;

    Display *d = XOpenDisplay((gchar*)0);
    guint n;

    if(d){
        XkbGetIndicatorState(d, XkbUseCoreKbd, &n);

        if((n & 1)){
            capslock_flag = TRUE;
        }
    }
    return capslock_flag;
}

gchar * get_date_string()
{
    char outstr[200];
    time_t t;
    struct tm *tmp;

    setlocale(LC_ALL, "");
    t = time(NULL);
    tmp = localtime(&t);
    if (tmp == NULL) {
        perror("localtime");
    }

    if (strftime(outstr, sizeof(outstr), _("%a,%b%d,%Y"), tmp) == 0) {
        fprintf(stderr, "strftime returned 0");
    }

    return g_strdup(outstr);
}

gboolean is_need_pwd (const gchar *username)
{
    gboolean needed = TRUE;
    GVariant *lock_need_pwd = NULL;
    GError *error = NULL;

    GDBusProxy *lock_proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SYSTEM,
            G_DBUS_PROXY_FLAGS_NONE,
            NULL,
            "com.deepin.dde.lock",
            "/com/deepin/dde/lock",
            "com.deepin.dde.lock",
            NULL,
            &error);

    g_assert(lock_proxy != NULL);
    if (error != NULL) {
        g_warning("connect com.deepin.dde.lock failed");
        g_clear_error(&error);
     }

    lock_need_pwd  = g_dbus_proxy_call_sync(lock_proxy,
                    "NeedPwd",
                    g_variant_new ("(s)", username),
                    G_DBUS_CALL_FLAGS_NONE,
                    -1,
                    NULL,
                    &error);

    g_assert(lock_need_pwd != NULL);
    if(error != NULL){
        g_clear_error (&error);
    }

    g_variant_get(lock_need_pwd, "(b)", &needed);

    g_variant_unref(lock_need_pwd);
    g_object_unref(lock_proxy);

    return needed;
}

