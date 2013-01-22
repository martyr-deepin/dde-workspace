#include <glib.h>
#include <gio/gio.h>
gboolean launcher_should_exit()
{
    GError* error = NULL;
    GDBusProxy* _proxy = g_dbus_proxy_new_for_bus_sync (G_BUS_TYPE_SESSION,
            G_DBUS_PROXY_FLAGS_DO_NOT_LOAD_PROPERTIES| G_DBUS_PROXY_FLAGS_DO_NOT_CONNECT_SIGNALS,
            NULL,
            "com.deepin.dde.dock",
            "/com/deepin/dde/dock",
            "com.deepin.dde.dock",
            NULL,
            &error);
    if (error) {
        g_debug("%s\n", error->message);
        g_error_free(error);
    }
    GVariant* r = NULL;
    r = g_dbus_proxy_call_sync (_proxy, "LauncherShouldExit",
            NULL,
            G_DBUS_CALL_FLAGS_NONE,
            -1,
            NULL,
            &error);
    if (error) {
        g_debug("%s\n", error->message);
        g_error_free(error);
    }
    gboolean ret;
    g_variant_get(r, "(b)", &ret);
    g_variant_unref(r);
    return ret;
}
