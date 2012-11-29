#include <gtk/gtk.h>
#include "i18n.h"

void item_rename(const char* old, const char* new)
{
    run_command2("mv", old, new);
}

void item_delete(const char** target, int n)
{
    printf("%d\n", n);
    if (n <= 0) return;

    GtkWidget *dialog = gtk_message_dialog_new (NULL,
            GTK_DIALOG_MODAL | GTK_DIALOG_DESTROY_WITH_PARENT,
            GTK_MESSAGE_QUESTION,
            GTK_BUTTONS_OK_CANCEL,
            _("do you want to delete following %d file(s) ?"),
            n);
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

    gtk_dialog_run (GTK_DIALOG (dialog));
    gtk_widget_destroy (dialog);

    //run_command2("rm", target);
}
