#include <stdlib.h>
#include <gtk/gtk.h>
#include <glib/gstdio.h>
#include <string.h>
#include "i18n.h"
#include "utils.h"
#include "dentry/entry.h"
#include "pixbuf.h"
#include "xdg_misc.h"
#include "jsextension.h"

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
    char* cmd_line=g_strdup_printf("deepin-system-settings %s\n", e_p);
    g_free(e_p);

    GError* error=NULL;
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

void desktop_run_deepin_software_center()
{
    char* cmd_line = g_strdup_printf("deepin-software-center");

    GError* error=NULL;
    GAppInfo* appinfo=g_app_info_create_from_commandline(cmd_line, NULL,
                                                           G_APP_INFO_CREATE_NONE,
                                                           &error);
    g_free(cmd_line);
    if (error != NULL)
    {
        g_debug("desktop_run_deepin_software_center error: %s", error->message);
        g_error_free(error);
    }
    error = NULL;
    g_app_info_launch(appinfo, NULL, NULL, &error);
    if (error!=NULL)
    {
        g_debug("desktop_run_deepin_software_center error: %s", error->message);
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

/*
 * Entry* desktop_get_trash_entry()
 * this function is defined in inotify_item.c because we will monitor the trash status
 * */

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
    char* ticon_path = NULL;
    char* p1_path = dentry_get_icon_path(p1);
    ticon_path = generate_directory_icon(p1_path, NULL, NULL, NULL);
    g_free (p1_path);

    return ticon_path;
}
