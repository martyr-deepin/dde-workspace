#include <gtk/gtk.h>
#include <X11/extensions/XTest.h>
#include <X11/extensions/shape.h>
#include "X_misc.h"
#include "jsextension.h"
#include "dcore.h"
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
    // gdk_keyboard_grab(gtk_widget_get_window(get_container()), FALSE, GDK_CURRENT_TIME);
    GdkWindow* window = gtk_widget_get_window(get_container());
    GdkDisplay* display = gdk_window_get_display(window);
    GdkDeviceManager* manager = gdk_display_get_device_manager(display);
    GList* devices = gdk_device_manager_list_devices(manager, GDK_DEVICE_TYPE_MASTER);
    GdkDevice* device = NULL;
    for (GList* dev = devices; dev != NULL; dev = dev->next) {
        device = GDK_DEVICE(dev->data);

        if (gdk_device_get_source(device) != GDK_SOURCE_KEYBOARD) {
            continue;
        }

        GdkGrabStatus res = gdk_device_grab(device,
                                            window,
                                            GDK_OWNERSHIP_NONE,
                                            FALSE,
                                            GDK_KEY_PRESS_MASK|GDK_KEY_RELEASE_MASK,
                                            NULL,
                                            GDK_CURRENT_TIME
                                           );
        switch (res) {
        case GDK_GRAB_ALREADY_GRABBED:
            g_warning("Grab falied, device %s is already grabbed.", gdk_device_get_name(device));
            break;
        case GDK_GRAB_INVALID_TIME:
            g_warning("Grab failed, the resource is grabbed more recently than the specified time.");
            break;
        case GDK_GRAB_NOT_VIEWABLE:
            g_warning("Grab falied, the window is not viewable.");
            break;
        case GDK_GRAB_FROZEN:
            g_warning("Grab falied, the resources is frozen.");
            break;
        case GDK_GRAB_SUCCESS:
            break;
        }
    }

    g_list_free(devices);
}

JS_EXPORT_API
void guide_enable_keyboard()
{
    // gdk_keyboard_ungrab(GDK_CURRENT_TIME);
    GdkWindow* window = gtk_widget_get_window(get_container());
    GdkDisplay* display = gdk_window_get_display(window);
    GdkDeviceManager* manager = gdk_display_get_device_manager(display);
    GList* devices = gdk_device_manager_list_devices(manager, GDK_DEVICE_TYPE_MASTER);
    GdkDevice* device = NULL;
    for (GList* dev = devices; dev != NULL; dev = dev->next) {
        device = GDK_DEVICE(dev->data);

        if (gdk_device_get_source(device) != GDK_SOURCE_KEYBOARD) {
            continue;
        }

        gdk_device_ungrab(device, GDK_CURRENT_TIME);
    }
    g_list_free(devices);
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
    //cairo_rectangle_int_t rectangle;
    //cairo_region_get_rectangle(dock_region,0,&rectangle);
    //int x0 = rectangle.x;
    //int y0 = rectangle.y;
    //int x1 = x0 + rectangle.width;
    //int y1 = y0 + rectangle.height;
    //g_message("dock_region:[%d,%d,%d,%d]",x0,y0,x1,y1);
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
gboolean guide_is_zone_launched()
{
    #define ZONE_ID_NAME "desktop.app.zone"
    return is_application_running(ZONE_ID_NAME);
}

JS_EXPORT_API
void guide_spawn_command_sync (const char* command,gboolean sync){
    GError *error = NULL;
    const gchar *cmd = g_strdup_printf ("%s",command);
    g_message ("g_spawn_command_line_sync:%s",cmd);
    if(sync){
        g_spawn_command_line_sync (cmd, NULL, NULL, NULL, &error);
    }else{
        g_spawn_command_line_async (cmd, &error);
    }
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
    const char* cmd = g_strdup_printf("cp %s '%s/'",src,DESKTOP_DIR());
    guide_spawn_command_sync(cmd,true);
}

JS_EXPORT_API
void guide_cursor_hide()
{
    GdkCursor* cursor;
    GdkWindow* window = gtk_widget_get_window(get_container());
    cursor = gdk_cursor_new(GDK_BLANK_CURSOR);
    gdk_window_set_cursor (window, cursor);
    g_object_unref(cursor);
}

JS_EXPORT_API
void guide_cursor_show()
{
    GdkCursor* cursor;
    GdkWindow* window = gtk_widget_get_window(get_container());
    cursor = gdk_cursor_new(GDK_LEFT_PTR);
    gdk_window_set_cursor (window, cursor);
    g_object_unref(cursor);
}

JS_EXPORT_API
void guide_toggle_show_desktop(gboolean show)
{
    int status = 0;
    if (show)
        status = 1;
    else
        status = 0;
    g_message("[%s]:===%d===,desktop status to %d",__func__, show, status);

    Display* dsp = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    static Atom _NET_SHOWING_DESKTOP = 0;
    if (_NET_SHOWING_DESKTOP == 0) {
        _NET_SHOWING_DESKTOP = gdk_x11_get_xatom_by_name("_NET_SHOWING_DESKTOP");
    }
    XClientMessageEvent event;
    event.type = ClientMessage;
    event.send_event = True;
    event.display = dsp;
    event.window = GDK_ROOT_WINDOW();
    event.message_type = _NET_SHOWING_DESKTOP;
    event.format = 32;
    event.data.l[0] = status;
    XSendEvent(dsp, GDK_ROOT_WINDOW(), False,
               SubstructureRedirectMask | SubstructureNotifyMask, (XEvent*)&event);
    XFlush(dsp);
}
