#include <glib.h>
#include <gio/gio.h>

void require_manager_trayicons()
{
    GError* err = NULL;
    GDBusProxy* proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SESSION,
                                                      G_DBUS_PROXY_FLAGS_NONE,
                                                      NULL,
                                                      "com.deepin.dde.TrayManager",
                                                      "/com/deepin/dde/TrayManager",
                                                      "com.deepin.dde.TrayManager",
                                                      NULL,
                                                      &err
                                                      );
    if (err != NULL) {
        g_warning("[%s:%s] get dbus proxy failed: %s", __FILE__, __func__,
                  err->message);
        g_error_free(err);
        return;
    }

    g_dbus_proxy_call_sync(proxy,
                           "RequireManageTrayIcons",
                           NULL,
                           G_DBUS_CALL_FLAGS_NONE,
                           -1,
                           NULL,
                           &err
                          );
    g_object_unref(proxy);
    if (err != NULL) {
        g_warning("[%s:%s] call RequireManageTrayIcons failed: %s", __FILE__,
                  __func__, err->message);
        g_error_free(err);
    }
}

