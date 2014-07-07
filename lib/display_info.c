#include <gdk/gdk.h>

#include "./dbus/dbus_introspect.h"
#include "display_info.h"

gboolean update_display_info(struct DisplayInfo* info)
{
    GError* error = NULL;
    GDBusProxy* proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SESSION,
                                                      G_DBUS_PROXY_FLAGS_NONE,
                                                      NULL,
                                                      DISPLAY_NAME,
                                                      DISPLAY_PATH,
                                                      DISPLAY_INTERFACE,
                                                      NULL,
                                                      &error
                                                      );
    if (error == NULL) {
        GVariant* res = g_dbus_proxy_get_cached_property(proxy, "PrimaryRect");
        g_variant_get(res, "(nnqq)", &info->x, &info->y, &info->width, &info->height);
        g_debug("%dx%d(%d,%d)", info->width, info->height, info->x, info->y);
        g_object_unref(proxy);
        return TRUE;
    } else {
        g_warning("[%s] connection dbus failed: %s", __func__, error->message);
        g_clear_error(&error);
        info->x = 0;
        info->y = 0;
        info->width = gdk_screen_width();
        info->height = gdk_screen_height();
        return FALSE;
    }
}


void listen_primary_changed_signal(GDBusSignalCallback handler, gpointer data, GDestroyNotify data_free_func)
{
    GError* err = NULL;
    static GDBusConnection* conn = NULL;
    if (conn == NULL ) {
        conn = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, &err);
    }
    if (err != NULL) {
        g_warning("[%s] get dbus failed: %s", __func__, err->message);
        g_clear_error(&err);
        return;
    }
    add_watch(conn, DISPLAY_PATH, DISPLAY_INTERFACE, PRIMARY_CHANGED_SIGNAL);
    g_dbus_connection_signal_subscribe(conn,
                                       DISPLAY_NAME,
                                       DISPLAY_INTERFACE,
                                       PRIMARY_CHANGED_SIGNAL,
                                       DISPLAY_PATH,
                                       NULL,
                                       G_DBUS_SIGNAL_FLAGS_NONE,
                                       handler,
                                       data,
                                       data_free_func
                                       );
}

