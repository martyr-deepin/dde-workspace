#include <dbus/dbus-glib.h>
#include "dbus_object_info.h"
#include <stdio.h>

void print_func(gpointer key, gpointer value, gpointer data_user)
{
    printf("%s\n", key);
}
int main1()
{
    DBusGConnection *con;

    g_type_init();

    con = dbus_g_bus_get(DBUS_BUS_SESSION,  NULL);
    if (con == NULL) {
        g_warning("ERRROR");
    }

    struct DBusObjectInfo* info =  get_build_object_info(con, 
            "org.gnome.Nautilus",
            "/org/gnome/Nautilus",
            "org.gnome.Nautilus.FileOperations");

    printf("%s\n", info->server);
    g_hash_table_foreach(info->methods, print_func , NULL);
    g_hash_table_foreach(info->properties, print_func, NULL);
    g_hash_table_foreach(info->signals, print_func, NULL);

    g_hash_table_unref(info->methods);
    g_hash_table_unref(info->properties);
    g_hash_table_unref(info->signals);
    g_free(info->server);
    g_free(info->path);
    g_free(info->iface);
    g_free(info);

    return 0;
}
