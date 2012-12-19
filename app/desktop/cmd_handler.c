#include <stdlib.h>
#include <gtk/gtk.h>
#include <glib/gstdio.h>
#include <string.h>
#include "i18n.h"
#include "utils.h"
#include "xdg_misc.h"

void item_rename(const char* old_name, const char* new_name)
{
    printf("item_rename[%s],[%s]\n", old_name, new_name);
    if (g_file_test(old_name, G_FILE_TEST_IS_DIR) == FALSE)
    {
        int n = strlen(old_name);
        if (n > 8 && g_ascii_strcasecmp(old_name + n - 8, ".desktop") == 0)
        {
            if (change_desktop_entry_name(old_name, new_name))
                return;
        }
    }
    gchar* base_path = g_path_get_dirname(old_name);
    gchar* new_path = g_build_filename(base_path, new_name, NULL);
    printf("item_rename normal file[%s],[%s]\n", base_path, new_path);
    g_rename(old_name, new_path);
    g_free(base_path);
    g_free(new_path);
}

void item_delete(const char** target, int n)
{
    printf("%d\n", n);
    if (n <= 0) return;

    GtkWidget *dialog = gtk_message_dialog_new (NULL,
            GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
            GTK_MESSAGE_QUESTION,
            GTK_BUTTONS_OK_CANCEL,
            _("do you want to delete following %d %s ?"),
            n,
            n > 1 ? "files" : "file");
    gtk_window_set_title(GTK_WINDOW(dialog), _("confirm"));

    if (n == 1)
        gtk_message_dialog_format_secondary_text (GTK_MESSAGE_DIALOG (dialog),
                "%s", target[0]);
    else if (n == 2)
        gtk_message_dialog_format_secondary_text (GTK_MESSAGE_DIALOG (dialog),
                "%s\n%s", target[0], target[1]);
    else if (n == 3)
        gtk_message_dialog_format_secondary_text (GTK_MESSAGE_DIALOG (dialog),
                "%s\n%s\n%s", target[0], target[1], target[2]);
    else
        gtk_message_dialog_format_secondary_text (GTK_MESSAGE_DIALOG (dialog),
                "%s\n%s\n%s\n...", target[0], target[1], target[2]);

    gint result = gtk_dialog_run (GTK_DIALOG (dialog));
    gtk_widget_destroy (dialog);

    switch (result)
    {
        case GTK_RESPONSE_OK:
            for (int i = 0; i < n; ++i)
                run_command2("rm", "-r -f", target[i]);
            break;
        default:
            break;
    }
}

void run_terminal()
{
    gchar* path = get_desktop_dir(0);
    gchar* full_param = g_strdup_printf("--working-directory=%s", path);
    run_command1("gnome-terminal", full_param);
    g_free(path);
    g_free(full_param);
}

void run_deepin_settings(const char* mod)
{
    run_command1("deepin-system-settings", mod);
}
