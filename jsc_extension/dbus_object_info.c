#include <dbus/dbus-glib.h>
#include <dbus/dbus-glib-lowlevel.h>
#include <string.h>
#include <glib.h>

#include "dbus_object_info.h"

struct DBusObjectInfo *c_obj_info;
struct Method *c_method;
struct Signal *c_signal;
struct Property *c_property;
const char* iface_name;

enum State {
    S_NONE,
    S_PENDING,
    S_METHOD,
    S_SIGNAL,
    S_PROPERTY
} state = S_NONE;


static 
void method_free(gpointer data)
{
    //TODO: MEMEORY LEAK 
    struct Method* m = (struct Method*)data;
    /*g_free(m->name);*/
    /*g_slist_free(m->signature_in);*/
    /*g_slist_free(m->signature_out);*/
    /*g_slist_free_full(m->signature_in, g_free);*/
    /*g_slist_free_full(m->signature_out, g_free);*/
}

static
void signal_free(gpointer data)
{
    struct Signal* s = (struct Signal*)data;
    g_free(s->name);
    g_slist_free_full(s->signature, g_free);
}


static
void property_free(gpointer data)
{
    struct Property* p = (struct Property*)data;
    g_free(p->name);
    g_free(p->signature);
}


static
void parse_property(const gchar **names, const gchar **values)
{
    const gchar **n_c = names;
    const gchar **v_c = values;

    while (*n_c) {
        if (g_strcmp0(*n_c, "type") == 0) {
            c_property->signature = g_strdup(*v_c);
        }
        if (g_strcmp0(*n_c, "name") == 0) {
            c_property->name = g_strdup(*v_c);
        }

        if (g_strcmp0(*n_c, "access") == 0) {
            if (g_strcmp0(*v_c, "read") == 0)
                c_property->access = READ;
            else if (g_strcmp0(*v_c, "readwrite") == 0) 
                c_property->access = READWRITE;
            else
                g_assert_not_reached();
        }
        n_c++;
        v_c++;
    }
}

static
void parse_signal(const gchar **names, const gchar **values)
{
    const gchar **n_c = names;
    const gchar **v_c = values;

    while (*n_c) {
        if (g_strcmp0(*n_c, "type") == 0) {
            c_signal->signature = 
                g_slist_append((GSList*)c_signal->signature, g_strdup(*v_c));
            return;
        }
        n_c++;
        v_c++;
    }
}

static
void parse_parms(const gchar **names, const gchar **values)
{
    const gchar **n_c = names;
    const gchar **v_c = values;
    gboolean in = TRUE;
    const gchar *type = NULL;

    while (*n_c) {
        if (g_strcmp0(*n_c, "type") == 0) {
            type = *v_c;
        }
        if (g_strcmp0(*n_c, "direction") == 0) {
            if (g_strcmp0(*v_c, "in") == 0)
                in = TRUE;
            else
                in = FALSE;
        }
        n_c++;
        v_c++;
    }
    g_assert(type != NULL);
    if (in)  {
        c_method->signature_in = 
            g_slist_append((GSList*)c_method->signature_in, g_strdup(type));
    } else {
        c_method->signature_out = 
            g_slist_append((GSList*)c_method->signature_out, g_strdup(type));
    }
}

static 
void parse_start(GMarkupParseContext* context,
        const gchar *element_name,
        const gchar **attribute_names,
        const gchar **attribute_values,
        gpointer user_data,
        GError **error)
{

    const gchar **name_cursor = attribute_names;
    const gchar **value_cursor = attribute_values;

    if (state == S_NONE && g_strcmp0(element_name, "interface") == 0) {
        while (*name_cursor) {
            if (g_strcmp0(*name_cursor, "name") == 0 &&
                g_strcmp0(*value_cursor, iface_name) == 0) {
                state = S_PENDING;
                return;
            }
            name_cursor++;
            value_cursor++;
        }
    }

    if (state != S_NONE) {
        if (g_strcmp0(element_name, "method") == 0) {
            state = S_METHOD;
            c_method = g_new0(struct Method, 1); 
            while (g_strcmp0(*name_cursor, "name") != 0) {
                name_cursor++;
                value_cursor++;
            }
            c_method->name = g_strdup(*value_cursor);
            return;
        }
        if (g_strcmp0(element_name, "signal") == 0) {
            state = S_SIGNAL;
            c_signal = g_new0(struct Signal, 1);
            while (g_strcmp0(*name_cursor, "name") != 0) {
                name_cursor++;
                value_cursor++;
            }
            c_signal->name = g_strdup(*value_cursor);
            return;
        }
        if (g_strcmp0(element_name, "property") == 0) {
            state = S_PROPERTY;
            c_property = g_new0(struct Property, 1);
            parse_property(attribute_names, attribute_values);
            return;
        }
    }

    switch (state) {
        case S_METHOD:
            parse_parms(attribute_names, attribute_values);
            break;
        case S_SIGNAL:
            parse_signal(attribute_names, attribute_values);
            break;
    }
}


static 
void parse_end(GMarkupParseContext *context,
        const gchar* element_name, gpointer user_data, GError **error)
{
    if (g_strcmp0(element_name, "interface") == 0) {
        state = S_NONE;
    }
    if (state == S_METHOD && g_strcmp0(element_name, "method") == 0) {
        state == S_PENDING;
        g_hash_table_insert(c_obj_info->methods, c_method->name, c_method);
    }
    if (state == S_PROPERTY && g_strcmp0(element_name, "property") == 0) {
        state == S_PENDING;
        g_hash_table_insert(c_obj_info->properties, 
                c_property->name, c_property);
    }

    if (state == S_SIGNAL && g_strcmp0(element_name, "signal") == 0) {
        state == S_PENDING;
        g_hash_table_insert(c_obj_info->signals, 
                c_signal->name, c_signal);
    }
}

static
void build_object_info(const char* xml, const char* interface)
{
    g_assert(xml != NULL);
    static GMarkupParser parser = {
        .start_element = parse_start,
        .end_element = parse_end,
        .text = NULL, 
        .passthrough = NULL,
        .error = NULL
    };
    iface_name = interface;

    GMarkupParseContext *context = g_markup_parse_context_new(&parser, 0, NULL, NULL);
    if (g_markup_parse_context_parse(context, xml, strlen(xml), NULL) 
            == FALSE) {
        g_warning("introspect's xml content error!\n");
    }
    iface_name = NULL;
    g_markup_parse_context_free(context);
}

char* fetch_object_info(DBusGConnection* con, 
        const char* server, const char* path)
{
    char* info = NULL;
    DBusGProxy *proxy = dbus_g_proxy_new_for_name(con,
            server, path,
            "org.freedesktop.DBus.Introspectable");
    if (!dbus_g_proxy_call(proxy, "Introspect", NULL, G_TYPE_INVALID,
            G_TYPE_STRING, &info, G_TYPE_INVALID)) {
        g_warning("ERROR WHEN CAAL");
    }
    g_object_unref(proxy);
    return info;
}

struct DBusObjectInfo* get_cache_object_info()
{
    //TODO: cached
     return NULL;
}

struct DBusObjectInfo* get_build_object_info(
        DBusGConnection* con,
        const char *server, const char* path,
        const char *interface)
{

    c_obj_info = get_cache_object_info(server, path, interface);
    if (c_obj_info != NULL) {
        return c_obj_info;
    }

    c_obj_info = g_new(struct DBusObjectInfo, 1);
    c_obj_info->connection = dbus_g_connection_get_connection(con);
    c_obj_info->methods = g_hash_table_new_full(g_str_hash, g_str_equal,
            NULL, method_free);
    c_obj_info->properties = g_hash_table_new_full(g_str_hash, g_str_equal,
            NULL, property_free);
    c_obj_info->signals = g_hash_table_new_full(g_str_hash, g_str_equal,
            NULL, signal_free);
    c_obj_info->server = g_strdup(server);
    c_obj_info->path = g_strdup(path);
    c_obj_info->iface = g_strdup(interface);

    //TODO: c_obj_info add to spool

    char* info_xml  = fetch_object_info(con, server, path);
    if (info_xml == NULL)
        return NULL;
    build_object_info(info_xml, interface);
    g_free(info_xml);
    return c_obj_info;
}
