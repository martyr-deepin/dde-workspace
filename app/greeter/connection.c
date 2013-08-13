#include "DBUS_greeter.h"
#include "jsextension.h"

DBUS_EXPORT_API
void dbus_handle_start_animation()
{
    js_post_message_simply("start-animation", NULL);
}


DBUS_EXPORT_API
void dbus_handle_stop_animation()
{
    js_post_message_simply("stop-animation", NULL);
}


DBUS_EXPORT_API
void dbus_handle_start_login()
{
    js_post_message_simply("start-login", NULL);
}
