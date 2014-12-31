#include <gtk/gtk.h>

#include "X_misc.h"
#include "jsextension.h"
#include "i18n.h"
#include "utils.h"

#include "background.h"

#include "jsextension.h"
#include "dwebview.h"
#include "session_register.h"
#include "display_info.h"

#define DOCK_SCHEMA_ID "com.deepin.dde.dock"
#define DISPLAY_MODE_KEY "display-mode"
#define FASHION_MODE 0
#define EFFICIENT_MODE 1
#define CLASSIC_MODE 2

void notify_primary_size()
{
    struct DisplayInfo info;
    update_primary_info(&info);
    JSObjectRef size_info = json_create();
    json_append_number(size_info, "x", info.x);
    json_append_number(size_info, "y", info.y);
    json_append_number(size_info, "width", info.width);
    json_append_number(size_info, "height", info.height);
    js_post_message("primary_size_changed", size_info);
}

JS_EXPORT_API
void guide_monitors_ok()
{
    notify_primary_size();
}

JS_EXPORT_API
void guide_emit_webview_ok()
{
    dde_session_register();
}

JS_EXPORT_API
gboolean guide_is_debug()
{
#ifdef NDEBUG
    return FALSE;
#endif
    return TRUE;
}

GtkWidget* get_container()
{
    static GtkWidget* container = NULL;
    if (container == NULL) {
        container = create_web_container (FALSE, TRUE);
    }
    return container;
}

PRIVATE
void monitors_changed_cb()
{
    g_debug("[%s] signal========",__func__);
    struct DisplayInfo rect_screen;
    update_screen_info(&rect_screen);
    widget_move_by_rect(get_container(),rect_screen);
    notify_primary_size();
}

JS_EXPORT_API
double guide_get_dock_displaymode()
{
    GSettings* settings = g_settings_new (DOCK_SCHEMA_ID);
    int  display_mode = g_settings_get_enum (settings, DISPLAY_MODE_KEY);
    g_debug ("[%s]: %d",__func__ ,display_mode);
    g_object_unref(settings);
    return display_mode;
}

JS_EXPORT_API
double guide_get_dock_app_index(const gchar* app)
{
    int index = -1;
    GSettings* gsettings = g_settings_new("com.deepin.dde.dock");
    char** values = g_settings_get_strv(gsettings, "docked-apps");
    for (int i = 0; values[i] != NULL; ++i) {
        g_debug("[%s]:values[%d]:%s;", __func__, i, values[i]);
        if(g_strcmp0(app,values[i]) == 0){
            index = i;
            break;
        }
    }
    g_strfreev(values);
    g_object_unref(gsettings);
    if (index == -1){
        g_warning("[%s]:the app:%s cannot find in dock", __func__, app);
    }
    return(index);
}


int main (int argc, char **argv)
{
    if (argc == 2 && 0 == g_strcmp0(argv[1], "-d"))
        g_setenv("G_MESSAGES_DEBUG", "all", FALSE);

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
    g_log_set_default_handler((GLogFunc)log_to_file, "dde-guide");

    if (!guide_is_debug()){
        struct DisplayInfo rect_screen;
        update_screen_info(&rect_screen);
        widget_move_by_rect(get_container(),rect_screen);
        listen_monitors_changed_signal(G_CALLBACK(monitors_changed_cb),NULL);
    }

    GtkWidget *webview = d_webview_new_with_uri (GET_HTML_PATH("guide"));
    gtk_container_add (GTK_CONTAINER(get_container()), GTK_WIDGET (webview));
    g_signal_connect(webview, "draw", G_CALLBACK(erase_background), NULL);

    gtk_widget_realize (get_container());
    gtk_widget_realize (webview);

    GdkWindow* gdkwindow = gtk_widget_get_window (get_container());
    if (!guide_is_debug())
        gdk_window_set_override_redirect (gdkwindow, TRUE);

    gtk_widget_show_all (get_container());

    gtk_main ();

    return 0;
}
