#include "dbus_object_info.h"
#include <stdio.h>

#define NUM 10

int main()
{

    g_type_init();

    DBusGConnection *con = dbus_g_bus_get(DBUS_BUS_SESSION,  NULL);
    if (con == NULL) {
        g_warning("ERRROR");
    }
    struct DBusObjectInfo info[NUM];
    for (int i=0; i<NUM; i++) {
        struct DBusObjectInfo* info =  build_object_info(con,
                "org.gnome.Shell",
                "/org/gnome/Shell",
                "org.gnome.Shell");
        dbus_object_info_free(info);
    }

    dbus_g_connection_unref(con);
    return 0;
}
