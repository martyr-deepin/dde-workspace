#include <glib.h>
#include "jsextension.h"

GHashTable* signals = NULL;

void js_post_message(const char* name, const char* format, ...)
{
    if (signals == NULL) {
        g_warning("signals has not init!\n");
        return;
    }

    JSContextRef ctx = get_global_context();
    JSObjectRef cb = g_hash_table_lookup(signals, name);

    if (cb != NULL) {
        if (format == NULL) {
            JSObjectCallAsFunction(ctx, cb, NULL, 0, NULL, NULL);
        } else {
            va_list args;
            va_start(args, format);
            char* json_str = g_strdup_vprintf(format, args);
            va_end(args);

            JSValueRef js_args[1];
            js_args[0] = json_from_cstr(ctx, json_str);
            g_free(json_str);
            JSObjectCallAsFunction(ctx, cb, NULL, 1, js_args, NULL);
        }
    } else {
        g_warning("signal %s has not connected!\n", name);
    }
}

void unprotect(gpointer data)
{
    JSContextRef ctx = get_global_context();
    JSValueUnprotect(ctx, (JSValueRef)data);
}

JSValueRef signal_connect(const char* type, JSValueRef value, JSData* js)
{
    if (signals == NULL) {
        signals = g_hash_table_new_full(g_str_hash, g_str_equal, g_free, unprotect);
    }
    JSObjectRef cb = JSValueToObject(js->ctx, value, js->exception);
    if (cb != NULL || !JSObjectIsFunction(js->ctx, cb)) {
        JSValueProtect(js->ctx, cb);
        g_hash_table_insert(signals, g_strdup(type), (gpointer)value);
        g_message("signal connect %s \n", type);
    } else {
        g_warning("signal_connect's second parameter must be an function object");
    }
}
