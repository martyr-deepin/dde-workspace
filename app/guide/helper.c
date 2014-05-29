#include <gtk/gtk.h>
#include <X11/extensions/shape.h>
#include "X_misc.h"
#include "jsextension.h"


GtkWidget* get_container();
JS_EXPORT_API
void guide_quit()
{
    gtk_main_quit();
}
JS_EXPORT_API
void guide_disable_right_click()
{
    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    XGrabButton(dpy, Button3, AnyModifier, DefaultRootWindow(dpy), True, ButtonPressMask | ButtonReleaseMask, GrabModeAsync, GrabModeAsync, None, None);
}
JS_EXPORT_API
void guide_enable_right_click()
{
    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    XUngrabButton(dpy, Button3, AnyModifier, DefaultRootWindow(dpy));
}
JS_EXPORT_API
void guide_disable_keyboard()
{
    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    XGrabKeyboard(dpy, DefaultRootWindow(dpy), True, GrabModeAsync, GrabModeAsync, CurrentTime);
}
JS_EXPORT_API
void guide_enable_keyboard()
{
    Display* dpy = GDK_DISPLAY_XDISPLAY(gdk_display_get_default());
    XUngrabKeyboard(dpy, CurrentTime);
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

JS_EXPORT_API
void guide_disable_dock_region()
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

JS_EXPORT_API
void guide_enable_dock_region()
{
    gdk_window_input_shape_combine_region(gtk_widget_get_window(get_container()), NULL, 0, 0);
}

