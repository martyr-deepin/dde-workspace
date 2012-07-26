#ifndef __DBUS_OBJECT_INFO__
#define __DBUS_OBJECT_INFO__
#include <glib.h>
#include <dbus/dbus.h>

#include <JavaScriptCore/JSObjectRef.h>
struct DBusObjectInfo {
    DBusConnection* connection;
    char* server;
    char* path;
    char* iface;

    GHashTable* methods;
    GHashTable* properties;
    GHashTable* signals;
}; 

struct Method {
    char* name;
    GSList* signature_in;
    GSList* signature_out;
};

struct Signal {
    char* name;
    GSList* signature;
    char* match_rule;
};

enum Access {
    READ,
    READWRITE
};
struct Property {
    char* name;
    GSList* signature;
    JSPropertyAttributes access;
};

struct DBusObjectInfo* 
get_build_object_info(DBusGConnection* con, const char *server,
        const char* path, const char *interface);

#endif
