#include <glib.h>
#include <gio/gio.h>


void call_require_manage_tray_icons(GObject* source_object G_GNUC_UNUSED,
                                    GAsyncResult* res G_GNUC_UNUSED,
                                    gpointer data G_GNUC_UNUSED)
{
    GError* err = NULL;
    GDBusProxy* proxy = g_dbus_proxy_new_finish(res, &err);
    if (err != NULL) {
        g_warning("[%s] get dbus proxy failed: %s", __func__, err->message);
        g_clear_error(&err);
    }

    g_dbus_proxy_call(proxy,
                      "RequireManageTrayIcons",
                      NULL,
                      G_DBUS_CALL_FLAGS_NONE,
                      -1,
                      NULL,
                      NULL,
                      NULL
                      );
    g_object_unref(proxy);
}

void require_manager_trayicons()
{
    GError* err = NULL;
    GDBusConnection* conn = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, &err);
    if (err != NULL) {
        g_warning("[%s] create dbus connection failed: %s", __func__, err->message);
        g_clear_error(&err);
        return;
    }

    g_dbus_proxy_new(conn,
                     G_DBUS_PROXY_FLAGS_NONE,
                     NULL,
                     "com.deepin.dde.TrayManager",
                     "/com/deepin/dde/TrayManager",
                     "com.deepin.dde.TrayManager",
                     NULL,
                     call_require_manage_tray_icons,
                     NULL
                    );
}

