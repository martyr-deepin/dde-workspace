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
        g_variant_unref(res);
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

gboolean update_screen_info(struct DisplayInfo* info)
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
        GVariant* height = g_dbus_proxy_get_cached_property(proxy, "ScreenHeight");
        GVariant* width = g_dbus_proxy_get_cached_property(proxy, "ScreenWidth");
        guint16 screenHeight = g_variant_get_uint16(height);
        guint16 screenWidth = g_variant_get_uint16(width);
        g_variant_unref(height);
        g_variant_unref(width);

        info->x = 0;
        info->y = 0;
        info->width = screenWidth;
        info->height = screenHeight;
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

void only_show_in_primary(GtkWidget* container)
{
    struct DisplayInfo primaryInfo;
    GdkGeometry geo = {0};
    geo.min_height = 0;
    geo.min_width = 0;

    update_display_info(&primaryInfo);
    g_debug("[%s] primaryInfo: %dx%d(%d, %d)", __func__, primaryInfo.width, primaryInfo.height, primaryInfo.x, primaryInfo.y);

    gtk_window_set_geometry_hints(GTK_WINDOW(container), NULL, &geo, GDK_HINT_MIN_SIZE);
    if (gtk_widget_get_realized(container)) {
        GdkWindow* gdk = gtk_widget_get_window(container);
        gdk_window_set_geometry_hints(gdk, &geo, GDK_HINT_MIN_SIZE);
        gdk_window_move_resize(gdk, primaryInfo.x, primaryInfo.y,primaryInfo.width,primaryInfo.height );
        gdk_window_flush(gdk);
    }
}

void only_show_in_primary_with_bg_in_others(GtkWidget* container,GtkWidget* webview)
{
    struct DisplayInfo primaryInfo;
    struct DisplayInfo screenInfo;
    GdkGeometry geo = {0};
    geo.min_height = 0;
    geo.min_width = 0;

    update_display_info(&primaryInfo);
    update_screen_info(&screenInfo);
    g_debug("[%s] primaryInfo: %dx%d(%d, %d)", __func__, primaryInfo.width, primaryInfo.height, primaryInfo.x, primaryInfo.y);
    g_debug("[%s] screenInfo: %dx%d(%d, %d)", __func__, screenInfo.width, screenInfo.height, screenInfo.x, screenInfo.y);

    gtk_window_set_geometry_hints(GTK_WINDOW(container), NULL, &geo, GDK_HINT_MIN_SIZE);
    gtk_widget_set_size_request(container, screenInfo.width, screenInfo.height);
    gtk_window_move(GTK_WINDOW(container), screenInfo.x, screenInfo.y);

    if (gtk_widget_get_realized(webview)) {
        GdkWindow* gdk = gtk_widget_get_window(webview);
        gdk_window_set_geometry_hints(gdk, &geo, GDK_HINT_MIN_SIZE);
        gdk_window_move_resize(gdk, primaryInfo.x, primaryInfo.y,primaryInfo.width,primaryInfo.height );
        gdk_window_flush(gdk);
    }
    //TODO:
    //1.you must js_post_message of screenInfo and primaryInfo in webview_ok to coffee
    //2.you must DCore.signal_connect screen_size_changed and primary_size_changed in coffee
    //3.you must set the width and height of document.body by screenInfo
    //4.you must set the width and height of main Widget by primaryInfo
    //demo:app/guide/guide.c ; resources/guide/js/main.coffee
}

