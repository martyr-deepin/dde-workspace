/**
 * Copyright (c) 2011 ~ 2014 Deepin, Inc.
 *               2011 ~ 2014 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 *              bluth <yuanchenglu001@gmail.com>
 * Maintainer:  snyh <snyh@snyh.org>
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

#include <stdlib.h>
#include <gtk/gtk.h>
#include <gdk/gdkx.h>
#include <glib/gstdio.h>
#include <string.h>
#include "i18n.h"
#include "utils.h"
#include "dentry/entry.h"
#include "pixbuf.h"
#include "xdg_misc.h"
#include "jsextension.h"
#include <gio/gdesktopappinfo.h>

//FIXME: implemented in lib/dentry/mime_actions.c
//       move to a suitable place?
void desktop_run_in_terminal(char* executable);
void desktop_run_terminal()
{
    desktop_run_in_terminal (NULL);
}

void desktop_run_deepin_settings(const char* mod)
{
    char* e_p=shell_escape(mod);
    g_free(e_p);

    char* cmd_line=g_strdup_printf("dde-control-center %s\n", e_p);
    GError* error=NULL;
    static char* zone = "zone";
    if (g_str_equal(mod,zone)){
        g_message("start zone settings!");
        cmd_line=g_strdup_printf("/usr/lib/deepin-daemon/dde-zone\n");
    }
    g_debug("desktop_run_deepin_settings mod :----%s----",cmd_line);

    GAppInfo* appinfo=g_app_info_create_from_commandline(cmd_line, NULL,
                                                           G_APP_INFO_CREATE_NONE,
                                                           &error);
    g_free (cmd_line);
    if (error!=NULL)
    {
        g_debug("desktop_run_deepin_settings error: %s", error->message);
        g_error_free(error);
    }
    error = NULL;
    g_app_info_launch(appinfo, NULL, NULL, &error);
    if (error!=NULL)
    {
        g_debug("desktop_run_deepin_settings error: %s", error->message);
        g_error_free(error);
    }
    g_object_unref(appinfo);
}

void desktop_open_trash_can()
{
    GFile* file = g_file_new_for_uri("trash:///");
    ArrayContainer fs = {0, 0};
    dentry_launch(file, fs);
    g_object_unref(file);
}

Entry* desktop_get_home_entry()
{
    return g_file_new_for_commandline_arg(g_get_home_dir());
}

Entry* desktop_get_computer_entry()
{
    return g_file_new_for_uri("computer:///");
}
char* desktop_get_transient_icon (Entry* p1)
{
    g_message("desktop_get_transient_icon");
    char* ticon_path = NULL;
    char* p1_path = dentry_get_icon_path(p1);
    g_message("p1_path:%s",p1_path);
    ticon_path = generate_directory_icon(p1_path, NULL, NULL, NULL);
    g_free (p1_path);

    return ticon_path;
}


gboolean force_get_input_focus(GtkWidget* widget)
{
    g_return_if_fail(gtk_widget_get_realized(widget));

    XSetInputFocus(gdk_x11_get_default_xdisplay(), GDK_WINDOW_XID(gtk_widget_get_window(widget)), RevertToPointerRoot, CurrentTime);
    return FALSE;
}
