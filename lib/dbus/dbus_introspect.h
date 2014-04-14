#ifndef __DBUS_INTROSPECTOR__
#define __DBUS_INTROSPECTOR__
#include <gio/gio.h>
#include <JavaScriptCore/JSBase.h>

JSObjectRef get_dbus_object(JSContextRef ctx, GDBusConnection* con,
        const char* server, const char* path, const char* iface, JSValueRef exception);
void reset_dbus_infos();
#endif

