#include <gtk/gtk.h>

#include "X_misc.h"
#include "jsextension.h"
#include "dwebview.h"
#include "i18n.h"
#include "utils.h"
#include "session_register.h"

#include "background.h"

GtkWidget* get_container() 
{
    static GtkWidget* container = NULL;
    if (container == NULL) {
	container = create_web_container (FALSE, TRUE);
    }
    return container;
}

JS_EXPORT_API
void guide_emit_webview_ok()
{
    dde_session_register();
}


gboolean is_livecd ()
{
    const gchar *filename = "/proc/cmdline";
    gchar *contents = NULL;
    gboolean result = FALSE;
    gsize length = 0;
    if (g_file_get_contents(filename,&contents,&length,NULL))
    {
        g_message("--------%s----",contents);
        gchar* ptr = g_strstr_len(contents, -1, "boot=casper");
        if (ptr == NULL) {
            g_message("not found boot=casper");
        } else {
            result = TRUE;
        }
        g_free(contents);
    }
    return result;
}

int main (int argc, char **argv)
{
    if (is_livecd()){
        dde_session_register();
        return 0;
    }
    
    
    if (is_application_running("com.deepin.dde.guide")) {
        g_warning("another instance of application dde-guide is running...\n");
        return 0;
    } else {
	singleton("com.deepin.dde.guide");
    }

    init_i18n ();

    gtk_init (&argc, &argv);

    GtkWidget *webview = d_webview_new_with_uri (GET_HTML_PATH("guide"));
    gtk_container_add (GTK_CONTAINER(get_container()), GTK_WIDGET (webview));
    g_signal_connect(webview, "draw", G_CALLBACK(erase_background), NULL);

    gtk_widget_realize (get_container());
    gtk_widget_realize (webview);

    GdkWindow* gdkwindow = gtk_widget_get_window (get_container());
    gdk_window_move_resize(gdkwindow, 0, 0, gdk_screen_width(), gdk_screen_height());

    gdk_window_set_override_redirect (gdkwindow, TRUE);

    gtk_widget_show_all (get_container());

    gtk_main ();

    return 0;
}

