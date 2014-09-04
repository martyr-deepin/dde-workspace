#include "dbus_introspect.h"
#include "dbus_object_info.h"
#include <JavaScriptCore/JSContextRef.h>
JSGlobalContextRef ctx = NULL;

JSGlobalContextRef get_global_context()
{
    return ctx;
}
int main()
{
    g_type_init();
    ctx = JSGlobalContextCreate(NULL);

    DBusGConnection *con = dbus_g_bus_get(DBUS_BUS_SESSION,  NULL);

    JSObjectRef obj = get_dbus_object(ctx, con,
            "org.gnome.Shell", "/org/gnome/Shell",
            "org.gnome.Shell");

    dbus_g_connection_unref(con);
    JSGlobalContextRelease(ctx);
    /*dbus_object_info_free(info);*/
}
