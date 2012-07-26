#include <dbus/dbus-glib.h>
#include <dbus/dbus.h>
#include <glib.h>
#include <JavaScriptCore/JavaScript.h>

#include "jsextension.h"
#include "dbus_introspect.h"

static gboolean init = FALSE;
static DBusGConnection* sys_con = NULL;
static DBusGConnection* session_con = NULL;


void dbus_init()
{
    dbus_g_thread_init();
    g_type_init();
    init = TRUE;
}

JSValueRef sys_object(
        const char* server,
        const char* object_path,
        const char* interface,
        JSData* js)
{
    if (!init) dbus_init();

    if (sys_con == NULL) {
        GError *error = NULL;
        sys_con = dbus_g_bus_get(DBUS_BUS_SYSTEM, &error);
        if (error != NULL) {
            g_warning("ERROR:%s\n", error->message);
            g_error_free(error);
        }
        g_assert(sys_con != NULL);
    }
    JSValueRef value = get_dynamic_object(js->ctx, sys_con,
            server, object_path, interface);
    if (value == NULL) {
        JSContextRef ctx = js->ctx;
        FILL_EXCEPTION((js->exception), "Can't dynamic build this dbus interface)");
    }
    return value;
}

JSValueRef session_object(
        const char* server,
        const char* object_path,
        const char* interface,
        JSData* js)
{ 
    if (!init) dbus_init();

    if (session_con == NULL) {
        GError *error = NULL;
        session_con = dbus_g_bus_get(DBUS_BUS_SESSION, &error);
        if (error != NULL) {
            g_warning("ERROR:%s\n", error->message);
            g_error_free(error);
        }
        g_assert(session_con != NULL);
    }
    JSValueRef value = get_dynamic_object(js->ctx, session_con,
            server, object_path, interface);
    if (value == NULL) {
        JSContextRef ctx = js->ctx;
        FILL_EXCEPTION((js->exception), "Can't dynamic build this dbus interface)");
    }
    return value;
}
