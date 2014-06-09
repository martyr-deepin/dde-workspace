#include "session_register.h"
#include <gio/gio.h>
static void dbus_dde_session_register(const char* arg0)
{
    GError *error = NULL;
    GDBusProxy* proxy = g_dbus_proxy_new_for_bus_sync(G_BUS_TYPE_SESSION,
                                                     0,
                                                     NULL,
                                                     "org.snyh.Test",
                                                     "/org/snyh/Test",
                                                     "org.snyh.Test",
                                                     NULL,
                                                     &error);
    if (error != NULL) {
        g_warning ("call dbus_dde_session_register on org.snyh.Test failed: %s",
        error->message);
        g_error_free(error);
    }
    if (proxy != NULL) {
        GVariant* params = NULL;
        params = g_variant_new("(s)", arg0);
        GVariant* retval = g_dbus_proxy_call_sync(proxy, "Register",
                                               params,
                                               G_DBUS_CALL_FLAGS_NONE,
                                               -1, NULL, NULL);
        if (retval != NULL) {
            g_variant_unref(retval);
        }
        g_object_unref(proxy);
    }
}
void dde_session_register()
{
    const char* cookie = g_getenv("DDE_SESSION_PROCESS_COOKIE_ID");
    if (cookie == NULL) {
	g_warning("not start by startdde");
	return;
    }
    dbus_dde_session_register(cookie);
}

