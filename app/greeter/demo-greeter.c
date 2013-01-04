#include <gtk/gtk.h>
#include <lightdm.h>
#include <glib.h>
#include <stdlib.h>

GtkWidget *login_win;
GtkWidget *user_entry;
GtkWidget *login_button;
GtkWidget *vbox;

LightDMGreeter *greeter;

static void show_prompt_cb(LightDMGreeter *greeter, const char *text, LightDMPromptType type)
{
    gtk_widget_show_all(login_win);
    gtk_entry_set_text(GTK_ENTRY(user_entry), "");
    gtk_button_set_label(GTK_BUTTON(login_button), "Hello");
}

static void authentication_complete_cb(LightDMGreeter *greeter)
{
    if (lightdm_greeter_get_is_authenticated(greeter))
        lightdm_greeter_start_session_sync(greeter, "xfce4", NULL);
    exit(EXIT_FAILURE);
}

static void login_button_cb(void)
{
    lightdm_greeter_respond(greeter, gtk_entry_get_text(GTK_ENTRY(user_entry)));
}

int main(int argc, char **argv)
{
    GMainLoop *main_loop;

    gtk_init(&argc, &argv);

    main_loop = g_main_loop_new(NULL, FALSE);
    login_win = gtk_window_new(GTK_WINDOW_TOPLEVEL);
    user_entry = gtk_entry_new();
    login_button = gtk_button_new();
    vbox = gtk_vbox_new(TRUE, 0);
    greeter = lightdm_greeter_new();

    gtk_box_pack_start(GTK_BOX(vbox), user_entry, TRUE, TRUE, 0);
    gtk_box_pack_start(GTK_BOX(vbox), login_button, TRUE, TRUE, 0);
    gtk_container_add(GTK_CONTAINER(login_win), vbox);

    g_signal_connect(greeter, "show-prompt", G_CALLBACK(show_prompt_cb), NULL);
    g_signal_connect(greeter, "authentication-complete", G_CALLBACK(authentication_complete_cb), NULL);
    g_signal_connect(login_button, "clicked", G_CALLBACK(login_button_cb), NULL);

    if (!lightdm_greeter_connect_sync(greeter, NULL))
        exit(EXIT_FAILURE);

    lightdm_greeter_authenticate(greeter, NULL);

    gtk_main();
    return 0;
}
