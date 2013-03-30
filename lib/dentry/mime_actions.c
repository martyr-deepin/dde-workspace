#include <glib/gi18n.h>
#include <gio/gio.h>
#include <gtk/gtk.h>

#include "xdg_misc.h"

#define TERMINAL_SCHEMA_ID "com.deepin.desktop.default-applications.terminal"
#define TERMINAL_KEY_EXEC  "exec"
#define TERMINAL_KEY_EXEC_ARG "exec-arg"

static GSettings* terminal_gsettings = NULL;

//used by dentry/mime_actions.c
void desktop_run_in_terminal(char* executable)
{
    GError* error = NULL;
    char* exec_val;
    char* cmd_line;

    if (terminal_gsettings == NULL)
        terminal_gsettings = g_settings_new(TERMINAL_SCHEMA_ID);

    exec_val = g_settings_get_string(terminal_gsettings,
                                     TERMINAL_KEY_EXEC);
    gchar* path = get_desktop_dir(0);
    if (executable == NULL)
    {
        cmd_line = g_strdup_printf("%s --working-directory=%s",
                                   exec_val, path);
    }
    else
    {
        char* exec_arg_val = g_settings_get_string (terminal_gsettings,
                                                    TERMINAL_KEY_EXEC_ARG);
        cmd_line = g_strdup_printf("%s --working-directory=%s %s %s", 
                                   exec_val, path, exec_arg_val, executable);
        g_free (exec_arg_val);
    }
    g_free(path);
    g_free(exec_val);

    GAppInfo* appinfo = g_app_info_create_from_commandline(cmd_line, NULL,
                                                           G_APP_INFO_CREATE_NONE,
                                                           &error);
    g_free(cmd_line);
    if (error!=NULL)
    {
        g_debug("desktop_run_terminal error: %s", error->message);
        g_error_free(error);
    }
    error = NULL;
    g_app_info_launch(appinfo, NULL, NULL, &error);
    if (error!=NULL)
    {
        g_debug("desktop_run_terminal error: %s", error->message);
        g_error_free(error);
    }

    g_object_unref(appinfo);
}

#define RESPONSE_RUN 1000
#define RESPONSE_DISPLAY 1001
#define RESPONSE_RUN_IN_TERMINAL 1002

static void
run_file  (GFile* file, GFile* _file_arg)
{
    char* cmd_line;

    char* file_path = g_file_get_path (file);
    if (_file_arg != NULL)
    {
        char* _file_arg_uri = g_file_get_uri (_file_arg);
        cmd_line = g_strdup_printf ("%s %s", file_path, _file_arg_uri);
	g_free (_file_arg_uri);
    }
    else
    {
        cmd_line = g_strdup (file_path);
    }
    g_free (file_path);

    g_spawn_command_line_async (cmd_line, NULL);
    g_free (cmd_line);
}

void desktop_run_in_terminal(char* executable);
static void
run_file_in_terminal (GFile* file)
{
    char* executable = g_file_get_path (file);
    desktop_run_in_terminal (executable);
    g_free (executable);
}

static void
display_file (GFile* file, const char* content_type)
{
    GAppInfo *app  = g_app_info_get_default_for_type(content_type, FALSE);
    GList* list = g_list_append(NULL, file);
    g_app_info_launch(app, list, NULL, NULL);
    g_list_free(list);
    g_object_unref(app);
}

void
activate_file (GFile* file, const char* content_type, 
               gboolean is_executable, GFile* _file_arg)
{
    char* file_name = g_file_get_basename (file);
    g_debug ("activate_file: %s", file_name);
    g_free (file_name);
    g_debug ("content_type: %s", content_type);

    if (is_executable &&
        g_content_type_can_be_executable (content_type))
    {
        //1. an executable text file. or an shell script
        if (g_content_type_is_a (content_type, "text/plain")) 
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
		run_file_in_terminal (file);
                break;
            case RESPONSE_DISPLAY:
                display_file (file, content_type);
                break;
            case RESPONSE_RUN:
                run_file (file, NULL);
                break;
            case GTK_RESPONSE_CANCEL:
                break;
            default:
                break;
            }
        }
        //2. an executable binary file
        else
        {
            run_file (file, _file_arg);
        }
    }
    //for non-executables just open it.
    else
    {
        display_file (file, content_type);
    }
}
