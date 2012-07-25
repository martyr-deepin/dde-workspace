#include <dbus/dbus-glib.h>
#include <glib.h>
#include <JavaScriptCore/JSObjectRef.h>

#include "ddesktop.h"
#include "dbus_introspect.h"

void dbus_init()
{
    dbus_g_thread_init();
    g_type_init();
}



JSValueRef system_bus(JSData* js)
{
    static JSObjectRef obj = NULL;
    if (obj == NULL) {
        GError *error = NULL;
        obj = JSObjectMake(js->ctx, NULL, 
                dbus_g_bus_get(DBUS_BUS_SYSTEM, NULL));
        JSValueProtect(js->ctx, obj);
    }
    return obj;
}



JSValueRef session_bus(JSData *js)
{
    static JSObjectRef obj = NULL;
    if (obj == NULL) {
        /*dbus_init();*/

        GError *error = NULL;
        DBusGConnection* con = dbus_g_bus_get(DBUS_BUS_SESSION, &error);
        if (error != NULL) {
            printf("ERROR:%s\n", error->message);
            g_error_free(error);
        }

        g_assert(con != NULL);
        obj = JSObjectMake(js->ctx, get_DBus_Bus_class(), con);
        g_assert(JSObjectGetPrivate(obj) != NULL);

        JSValueProtect(js->ctx, obj);
    }
    return obj;
}

JSValueRef get_object(
        JSValueRef js_con,
        const char* server,
        const char* object_path,
        const char* interface,
        JSData* js)
{
    DBusGConnection *con = JSObjectGetPrivate((JSObjectRef)js_con);
    g_assert(con != NULL);
    return get_dynamic_object(js->ctx, con,
            server, object_path, interface);
}
