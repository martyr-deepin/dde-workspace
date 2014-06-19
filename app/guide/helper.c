#include <gtk/gtk.h>
#include <X11/extensions/XTest.h>
#include <X11/extensions/shape.h>
#include "X_misc.h"
#include "jsextension.h"
#include <X11/Xlib.h>
#include "xdg_misc.h"
#include "utils.h"

GtkWidget* get_container();
JS_EXPORT_API
void guide_quit()
{
    gtk_main_quit();
}
                
// only guide has left click ,not right_click
// desktop launcher dock all event disable
JS_EXPORT_API
void guide_disable_right_click()
{
    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    XGrabButton(dpy, Button3, AnyModifier, DefaultRootWindow(dpy), True, ButtonPressMask | ButtonReleaseMask, GrabModeAsync, GrabModeAsync, None, None);
}

// only guide has left click and right_click
// desktop launcher dock all event disable
JS_EXPORT_API
void guide_enable_right_click()
{
    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    XUngrabButton(dpy, Button3, AnyModifier, DefaultRootWindow(dpy));
}
JS_EXPORT_API
void guide_disable_keyboard()
{
    gdk_keyboard_grab(gtk_widget_get_window(get_container()), FALSE, GDK_CURRENT_TIME);
}
JS_EXPORT_API
void guide_enable_keyboard()
{
    gdk_keyboard_ungrab(GDK_CURRENT_TIME);
}

Window get_dock_xid()
{
    GDBusProxy *dock_proxy = NULL;
    GError *error = NULL;
    GVariant *dock_xid = NULL;

    dock_proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SESSION,
                                                G_DBUS_PROXY_FLAGS_NONE,
                                                NULL,
                                                "com.deepin.dde.dock",
                                                "/com/deepin/dde/dock",
                                                "com.deepin.dde.dock",
                                                NULL,
                                                &error);

    if (error != NULL) {
        g_warning ("get_dock_xid:dock proxy %s\n", error->message);
        g_error_free (error);
        g_object_unref (dock_proxy);
        return 0;
    }
    error = NULL;

    dock_xid = g_dbus_proxy_call_sync (dock_proxy,
                            "Xid",
                            g_variant_new("()"),
                            G_DBUS_CALL_FLAGS_NONE,
                            -1,
                            NULL,
                            &error);

    if (error != NULL) {
        g_warning ("get_dock_xid:Xid %s\n", error->message);
        g_error_free (error);
        g_object_unref (dock_proxy);
        return 0;
    }

    if (dock_xid == NULL) {
        g_warning ("get_dock_xid:Xid is NULL.\n");
        g_error_free (error);
        g_object_unref (dock_proxy);
        return 0;
    }

    error = NULL;
    g_object_unref (dock_proxy);
    guint64 xid = 0;
    g_variant_get(dock_xid, "(t)", &xid);
    g_message("get_dock_xid:xid:%lu",xid);
    return xid;
}


// guide all event disable
// desktop launcher all event enable
// dock all event disable
JS_EXPORT_API
void guide_disable_guide_region()
{
    //TODO: find the dock XID
    Window dock = get_dock_xid();
    if(dock == 0){
        g_warning("get_dock_xid error and return 0.");
        return;
    }
    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    cairo_region_t* dock_region = get_window_input_region(dpy, dock);
    gdk_window_input_shape_combine_region(gtk_widget_get_window(get_container()), dock_region, 0, 0);
    cairo_region_destroy(dock_region);
}

// guide all event enable
// desktop launcher dock all event disbable
JS_EXPORT_API
void guide_enable_guide_region()
{
    gdk_window_input_shape_combine_region(gtk_widget_get_window(get_container()), NULL, 0, 0);
}

JS_EXPORT_API
void guide_restack()
{
    gdk_window_restack(gtk_widget_get_window(get_container()), NULL, TRUE);
}


JS_EXPORT_API
void guide_simulate_click(double type)
{
    /*type:
     *1: left click
     *2: copy
     *3: right click
     *4: scroll up
     *5: scroll down
     */
    GError *error = NULL;
    const gchar *cmd = g_strdup_printf ("xdotool click %d\n",(int)type);
    g_message ("guide_simulate_click:%s",cmd);
    g_spawn_command_line_sync (cmd, NULL, NULL, NULL, &error);
    if (error != NULL) {
        g_warning ("%s failed:%s\n",cmd, error->message);
        g_error_free (error);
        error = NULL;
    }
}

JS_EXPORT_API
void guide_simulate_input(double input)
{
    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    KeyCode keycode = XKeysymToKeycode(dpy,(int)input);
    guide_enable_keyboard();
    XTestFakeKeyEvent(dpy, keycode, TRUE, 0);
    XTestFakeKeyEvent(dpy, keycode, FALSE, 0);
    guide_disable_keyboard();
}

JS_EXPORT_API
void guide_run_deepin_settings(const char* cmd)
{
    GError* error=NULL;
    char* cmd_line=g_strdup_printf("%s\n",cmd);
    g_message("run_deepin_settings cmd :----%s----",cmd_line);
    
    GAppInfo* appinfo=g_app_info_create_from_commandline(cmd_line, NULL,
                                                           G_APP_INFO_CREATE_NONE,
                                                           &error);
    g_free (cmd_line);
    if (error!=NULL)
    {
        g_debug("run_deepin_settings error: %s", error->message);
        g_error_free(error);
    }
    error = NULL;
    g_app_info_launch(appinfo, NULL, NULL, &error);
    if (error!=NULL)
    {
        g_debug("run_deepin_settings error: %s", error->message);
        g_error_free(error);
    }
    g_object_unref(appinfo);
}



JS_EXPORT_API
gboolean guide_is_zone_launched()
{
    #define ZONE_ID_NAME "desktop.app.zone"   
    return is_application_running(ZONE_ID_NAME);
}

JS_EXPORT_API
void guide_spawn_command_sync (const char* command){
    GError *error = NULL;
    const gchar *cmd = g_strdup_printf ("%s",command);
    g_message ("g_spawn_command_line_sync:%s",cmd);
    g_spawn_command_line_sync (cmd, NULL, NULL, NULL, &error);
    if (error != NULL) {
        g_warning ("%s failed:%s\n",cmd, error->message);
        g_error_free (error);
        error = NULL;
    }
}

JS_EXPORT_API
void guide_set_focus(gboolean focus)
{
    GdkWindow* gdkwindow = gtk_widget_get_window (get_container());
    gdk_window_set_focus_on_map (gdkwindow, focus);
    gdk_window_set_accept_focus (gdkwindow, focus);
    gdk_window_set_override_redirect(gdkwindow, !focus);
 }


JS_EXPORT_API
void guide_OpenUrl(const char* url)
{
    if ( url == NULL || url[0] == '\0' ) {
        g_warning ("url error\n");
        return ;
    }

    if (!dcore_open_browser(url)) {
        g_warning("browser url failed\n");
        return ;
    }

    return ;
}




JS_EXPORT_API
void guide_copy_file_to_desktop(const char* src)
{
    const char* cmd = g_strdup_printf("cp %s %s/",src,DESKTOP_DIR());
    guide_spawn_command_sync(cmd);
}

