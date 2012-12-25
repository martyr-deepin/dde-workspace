#include <stdlib.h>
#include <gtk/gtk.h>
#include <glib/gstdio.h>
#include <string.h>
#include "i18n.h"
#include "utils.h"
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
