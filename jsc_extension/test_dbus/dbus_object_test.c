#include <dbus/dbus-glib.h>
#include "dbus_object_info.h"
#include <stdio.h>

void info_free(struct DBusObjectInfo* info) 
{
    g_hash_table_unref(info->methods);
    g_hash_table_unref(info->properties);
    g_hash_table_unref(info->signals);
    g_free(info->server);
    g_free(info->path);
    g_free(info->iface);

    g_free(info);
}
int main()
{

    g_type_init();

    DBusGConnection *con = dbus_g_bus_get(DBUS_BUS_SESSION,  NULL);
    if (con == NULL) {
        g_warning("ERRROR");
    }

    struct DBusObjectInfo* info =  get_build_object_info(con, 
            "org.gnome.Shell",
            "/org/gnome/Shell",
            "org.gnome.Shell");
    dbus_g_connection_unref(con);

    info_free(info);

    return 0;
}
