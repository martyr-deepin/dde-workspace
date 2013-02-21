#include <glib/gi18n.h>
#include <gio/gio.h>
#include <gtk/gtk.h>

#define RESPONSE_RUN 1000
#define RESPONSE_DISPLAY 1001
#define RESPONSE_RUN_IN_TERMINAL 1002

/*
 *      @file: 
 *      @content_type: 
 *      @is_executable:
 */
void 
activate_file (GFile* file, const char* content_type, gboolean is_executable)
{
    //an executable text file.
    if (is_executable &&
        g_str_has_prefix (content_type, "text")&&
        g_content_type_can_be_executable (content_type))
    {
        GtkWidget* dialog;
        int response;
        char* file_name;
        char* prompt;
        char* detail;

        file_name = g_file_get_basename (file);
        prompt = g_strdup_printf (_("Do you want to run \"%s\", or display its contents?"), file_name);
        detail = g_strdup_printf (_("\"%s\" is an executable text file."), file_name);
        g_free (file_name);
        //create prompt dialog
        dialog = gtk_message_dialog_new (NULL, 
                                         GTK_DIALOG_MODAL,
                                         GTK_MESSAGE_QUESTION, 
                                         GTK_BUTTONS_NONE,
                                         NULL);
        g_object_set (dialog, "text", prompt, "secondary-text", detail, NULL);
        g_free (prompt);
        g_free (detail);
        gtk_dialog_add_button (GTK_DIALOG(dialog), _("Run in _Terminal"), RESPONSE_RUN_IN_TERMINAL);
        gtk_dialog_add_button (GTK_DIALOG(dialog), _("_Display"), RESPONSE_DISPLAY);
        gtk_dialog_add_button (GTK_DIALOG(dialog), GTK_STOCK_CANCEL, GTK_RESPONSE_CANCEL);
        gtk_dialog_add_button (GTK_DIALOG(dialog), _("_Run"), RESPONSE_RUN);
        gtk_dialog_set_default_response (GTK_DIALOG(dialog), GTK_RESPONSE_CANCEL);

        gtk_widget_show (GTK_WIDGET (dialog));

        response = gtk_dialog_run (GTK_DIALOG(dialog));
        gtk_widget_destroy (GTK_WIDGET (dialog));

        switch (response)
        {
            case RESPONSE_RUN_IN_TERMINAL:
                break;
            case RESPONSE_DISPLAY:
                break;
            case RESPONSE_RUN:
                break;
            case GTK_RESPONSE_CANCEL:
                break;
            default:
                break;
        }
    }
    else
    {
        char* file_name = g_file_get_basename (file);
        g_debug ("activate_file: %s", file_name);
        g_free (file_name);
        GAppInfo *app  = g_app_info_get_default_for_type(content_type, FALSE);
        GList* list = g_list_append(NULL, file);
        g_app_info_launch(app, list, NULL, NULL);
        g_list_free(list);
        g_object_unref(app);
    }
}
