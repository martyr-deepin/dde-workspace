#include <time.h>
#include <string.h>
#include "i18n.h"
#include "date_time.h"
#include <locale.h>
#include <gio/gio.h>


static void listen_use_24_hour(GDBusProxy* proxy G_GNUC_UNUSED,
                               GVariant* changed_properties,
                               GStrv invalidated_properties G_GNUC_UNUSED,
                               gpointer fn)
{
    GVariantIter array_iter;
    g_variant_iter_init(&array_iter, changed_properties);

    gchar* key = NULL;
    GVariant* value = NULL;
    while (g_variant_iter_next(&array_iter, "{sv}", &key, &value)) {
        if (g_strcmp0(key, "Use24HourDisplay") == 0) {
            gboolean use24 = g_variant_get_boolean(value);
            if (fn != NULL) {
                ((use_24_hour_handler)fn)(use24 ? 24 : 12);
            }
            g_variant_unref(value);
            g_free(key);
            break;
        }
        g_variant_unref(value);
        g_free(key);
    }
}

static void dbus_ready(GObject* source_object G_GNUC_UNUSED, GAsyncResult* res, gpointer fn)
{
    GError* err = NULL;
    GDBusProxy* proxy = g_dbus_proxy_new_finish(res, &err);
    if (err != NULL) {
        g_warning("%s", err->message);
        g_clear_error(&err);
        return;
    }

    g_signal_connect(proxy, "g-properties-changed", G_CALLBACK(listen_use_24_hour), fn);
}


void listen_use_24_hour_changed(use_24_hour_handler fn)
{
    static GDBusConnection* conn = NULL;
    if (conn == NULL) {
        GError* err = NULL;
        conn = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, &err);
        if (err != NULL ) {
            g_warning("%s", err->message);
            g_clear_error(&err);
            return;
        }
    }

    g_dbus_proxy_new(conn,
                     G_DBUS_PROXY_FLAGS_NONE,
                     NULL,
                     "com.deepin.daemon.DateAndTime",
                     "/com/deepin/daemon/DateAndTime",
                     "com.deepin.daemon.DateAndTime",
                     NULL,
                     dbus_ready,
                     fn
                    );
}


char* dock_get_time(const char* format)
{
    time_t t = time(NULL);
    char time_str[200] = {0};
    strftime(time_str, sizeof(time_str), format, localtime(&t));

    return g_strdup(time_str);
}

