#include <stdlib.h>
#include <gtk/gtk.h>
#include <glib/gstdio.h>
#include <string.h>
#include "i18n.h"
#include "utils.h"
#include "dentry/entry.h"
#include "xdg_misc.h"
#include "jsextension.h"

#define TERMINAL_SCHEMA_ID "com.deepin.desktop.default-applications.terminal"
#define TERMINAL_KEY_EXEC  "exec"
#define TERMINAL_KEY_EXEC_ARG "exec-arg"

static GSettings* terminal_gsettings = NULL;
void desktop_run_terminal()
{
    if (terminal_gsettings == NULL)
        terminal_gsettings = g_settings_new(TERMINAL_SCHEMA_ID);

    char* exec_val = g_settings_get_string(terminal_gsettings,
                                            TERMINAL_KEY_EXEC);
    //char* exec_arg_val = g_settings_get_string (terminal_gsettings,
    //                                        TERMINAL_KEY_EXEC_ARG);
    GError* error = NULL;

    gchar* path = get_desktop_dir(0);
    gchar* cmd_line = g_strdup_printf("%s --working-directory=%s", exec_val, path);

    GAppInfo* appinfo = g_app_info_create_from_commandline(cmd_line, NULL,
                                                           G_APP_INFO_CREATE_NONE,
                                                           &error);
    if (error!=NULL)
    {
        g_debug("desktop_run_terminal error: %s", error->message);
	g_error_free(error);
    }
    error = NULL;
    g_app_info_launch (appinfo, NULL, NULL, &error);
    if (error!=NULL)
    {
        g_debug("desktop_run_terminal error: %s", error->message);
	g_error_free(error);
    }
    
    g_app_info_delete (appinfo);
    g_free(path);
    g_free(cmd_line);
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
    return g_file_new_for_commandline_arg(g_get_home_dir());
}

Entry* desktop_get_computer_entry()
{
    return g_file_new_for_uri("computer:///");
}
