#include <gio/gio.h>
#include "dbus.h"

#define APP_NAME "launcher"
#define APP_DBUS_NAME     "com.deepin.dde."APP_NAME
#define APP_DBUS_OBJ       "/com/deepin/dde/"APP_NAME
#define APP_DBUS_IFACE     "com.deepin.dde."APP_NAME

static const char* _dbus_iface_xml =
"<?xml version=\"1.0\"?>\n"
"<node>\n"
"    <interface name=\""APP_DBUS_IFACE"\">\n"
"       <method name=\"Show\">\n"
"       </method>\n"
"       <method name=\"Hide\">\n"
"       </method>\n"
"       <method name=\"Exit\">\n"
"       </method>\n"
"    </interface>\n"
"</node>\n"
;

static void
_bus_method_call (GDBusConnection * connection,
                 const gchar * sender, const gchar * object_path, const gchar * interface,
                 const gchar * method, GVariant * params,
                 GDBusMethodInvocation * invocation, gpointer user_data)
{
    g_debug ("bus_method_call");

    GVariant * retval = NULL;
    GError * error = NULL;

    if (g_strcmp0 (method, "Show") == 0) {
        launcher_show();
    } else if (g_strcmp0(method, "Hide") == 0) {
        launcher_hide();
    } else {
        g_warning ("Calling method '%s' on "APP_NAME"and it's unknown", method);
    }

    if (error != NULL) {
        g_dbus_method_invocation_return_dbus_error (invocation,
                "com.deepin.dde."APP_NAME".Error", 
                error->message);
        g_error_free (error);
    } else {
        g_dbus_method_invocation_return_value (invocation, retval);
    }

    return;
}

static guint _service_owner_id;
static guint _service_reg_id;        //used for unregister an object path
static guint retry_reg_timeout_id;   //timer used for retrying dbus name registration.
static GDBusConnection* _connection;

//internal functions
static gboolean _retry_registration (gpointer user_data);
static void _on_bus_acquired (GDBusConnection * connection, const gchar * name, gpointer user_data);
static void _on_name_acquired (GDBusConnection * connection, const gchar * name, gpointer user_data);
static void _on_name_lost (GDBusConnection * connection, const gchar * name, gpointer user_data);
static void _bus_method_call (GDBusConnection * connection, const gchar * sender,
                             const gchar * object_path, const gchar * interface,
                             const gchar * method, GVariant * params,
                             GDBusMethodInvocation * invocation, gpointer user_data);

static GDBusNodeInfo *      node_info = NULL;
static GDBusInterfaceInfo * interface_info = NULL;
static GDBusInterfaceVTable interface_table = { 
    method_call:   _bus_method_call,
    get_property:   NULL, /* No properties */
    set_property:   NULL  /* No properties */
};

void setup_dbus_service ()
{
    GError* error = NULL;
    node_info = g_dbus_node_info_new_for_xml (_dbus_iface_xml, &error);
    if (error != NULL)
    {
        g_critical ("Unable to parse interface xml: %s", error->message);
        g_error_free (error);
    }

    interface_info = g_dbus_node_info_lookup_interface (node_info, APP_DBUS_IFACE);
    if (interface_info == NULL)
    {
        g_critical ("Unable to find interface '"APP_DBUS_IFACE"'");
    }

    _service_owner_id = 0;
    _service_reg_id = 0;
    retry_reg_timeout_id = 0;

    _retry_registration (NULL);
}

static gboolean
_retry_registration (gpointer user_data)
{

    _service_owner_id = g_bus_own_name (G_BUS_TYPE_SESSION, 
            APP_DBUS_NAME, 
            G_BUS_NAME_OWNER_FLAGS_NONE,
            _service_reg_id ? NULL : _on_bus_acquired, 
            _on_name_acquired, 
            _on_name_lost,
            NULL, 
            NULL);
    return TRUE;
}

static void 
_on_bus_acquired (GDBusConnection * connection,
        const gchar * name,
        gpointer user_data)
{
    g_debug ("on_bus_acquired");

    _connection = connection;

    //register object.
    GError* error = NULL;
    _service_reg_id = g_dbus_connection_register_object (connection,
            APP_DBUS_OBJ,
            interface_info, 
            &interface_table,
            user_data, 
            NULL, 
            &error);

    if (error != NULL) 
    {
        g_critical ("Unable to register the object to DBus: %s", error->message);
        g_error_free (error);
        g_bus_unown_name (_service_owner_id);
        _service_owner_id = 0;
        retry_reg_timeout_id = g_timeout_add_seconds(1, _retry_registration, NULL);
        return;
    }

    return;
}

static void
_on_name_acquired (GDBusConnection * connection, 
        const gchar * name, 
        gpointer user_data)
{
    g_debug ("Dbus name acquired");
}

static void
_on_name_lost (GDBusConnection * connection, 
        const gchar * name, 
        gpointer user_data)
{
    if (connection == NULL) 
    {
        g_critical("Unable to get a connection to DBus");
    }
    else
    {
        g_critical("Unable to claim the name %s", APP_DBUS_NAME);
    }

    _service_owner_id = 0;
}
