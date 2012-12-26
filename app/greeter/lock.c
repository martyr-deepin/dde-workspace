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
#include "jsextension.h"
#include "dwebview.h"
#include "i18n.h"
#include "utils.h"

#define LOCK_HTML_PATH "file://"RESOURCE_DIR"/greeter/lock.html"

GtkWidget* lock_container = NULL;

int main(int argc, char **argv)
{
    init_i18n();
    gtk_init(&argc, &argv);

    lock_container = create_web_container(FALSE, TRUE);
    gtk_window_set_decorated(GTK_WINDOW(lock_container), FALSE);
    gtk_window_fullscreen(GTK_WINDOW(lock_container));

    GtkWidget *webview = d_webview_new_with_uri(LOCK_HTML_PATH);

    gtk_container_add(GTK_CONTAINER(lock_container), GTK_WIDGET(webview));

    g_signal_connect (lock_container , "destroy", G_CALLBACK (gtk_main_quit), NULL);

    dcore_run_command("xtrlock");

    gtk_widget_realize(lock_container);

    gtk_widget_show_all(lock_container);

    gtk_main();
    return 0;
}
