#include <stdlib.h>
#include <gtk/gtk.h>
#include <glib/gstdio.h>
#include <string.h>
#include "i18n.h"
#include "utils.h"
#include "dentry/entry.h"
#include "xdg_misc.h"
#include "jsextension.h"

void desktop_run_terminal()
{
    gchar* path = get_desktop_dir(0);
    gchar* full_param = g_strdup_printf("--working-directory=%s", path);
    dcore_run_command1("gnome-terminal", full_param);
    g_free(path);
    g_free(full_param);
}

void desktop_run_deepin_settings(const char* mod)
{
    dcore_run_command1("deepin-system-settings", mod);
}

void desktop_open_trash_can()
{
    GFile* file = g_file_new_for_uri("trash:///");
    ArrayContainer fs = {0, 0};
    dentry_launch(file, fs);
    g_object_unref(file);
}

/*
 * Entry* desktop_get_trash_entry()
 * this function is defined in inotify_item.c because we will monitor the trash status 
 * */

Entry* desktop_get_home_entry()
{
    return g_file_new_for_path(g_get_home_dir());
}

Entry* desktop_get_computer_entry()
{
    return g_file_new_for_uri("computer:///");
}
