#include <dbus/dbus.h>
#include <dbus/dbus-glib.h>
#include <JavaScriptCore/JSObjectRef.h>
#include <JavaScriptCore/JSStringRef.h>
#include <glib.h>

#include "dbus_introspect.h"
#include "dbus_object_info.h"
#include "dbus_js_convert.h"
#include "ddesktop.h"

#include <stdio.h>

void pp(gpointer data, gpointer user_data)
{
    const char* s = data;
    puts(s);
}

JSValueRef call_sync(JSContextRef ctx, DBusConnection* con, 
        DBusMessage *msg, GSList* sigs_out)
{
    char *sig  = g_slist_nth_data(sigs_out, 0);

    g_assert(msg != NULL);

    DBusMessage* reply = dbus_connection_send_with_reply_and_block(
            con,
            msg, -1, NULL);
    //TODO: error handle
    //
    
    if (reply == NULL) {
        g_warning("Faild call this function...");
        return JSValueMakeUndefined(ctx);
    } else {
        if (dbus_message_get_type(reply) == DBUS_MESSAGE_TYPE_METHOD_RETURN) {
            DBusMessageIter iter;
            dbus_message_iter_init(reply, &iter);

            int num = g_slist_length(sigs_out);
            if (num == 0) {
                return JSValueMakeUndefined(ctx);
            } else if (num == 1) {
                return dbus_to_js(ctx, &iter);
            } else {
                JSValueRef args[num];
                for (int i=0; i<num; i++) {
                    args[i] = dbus_to_js(ctx, &iter);
                    dbus_message_iter_next(&iter);
                }
                return JSObjectMakeArray(ctx, num, args, NULL);
            }
        } else {
            g_warning("Faild call this function...");
            return JSValueMakeUndefined(ctx);
        }
    }
}

static 
JSValueRef dynamic_function(JSContextRef ctx,
                            JSObjectRef function,
                            JSObjectRef this,
                            size_t argumentCount,
                            const JSValueRef arguments[],
                            JSValueRef *exception)
{
    JSValueRef ret;

    struct DBusObjectInfo* obj_info = JSObjectGetPrivate(this);

    JSStringRef name_str = JSStringCreateWithUTF8CString("name");
    JSValueRef js_func_name = JSObjectGetProperty(ctx, function, 
            name_str, NULL);
    JSStringRelease(name_str);

    char* func_name = jsvalue_to_cstr(ctx, js_func_name);

    struct Method *m = g_hash_table_lookup(obj_info->methods, func_name);
    g_assert(obj_info->methods != NULL);


    GSList* sigs_in = m->signature_in;
    if (g_slist_length(sigs_in) != argumentCount) {
        FILL_EXCEPTION(exception, "Signature didn't mached");
        return NULL;
    }
    GSList* sigs_out = m->signature_out;

    DBusMessage* msg = dbus_message_new_method_call(
            obj_info->server, 
            obj_info->path, 
            obj_info->iface, 
            func_name);
    g_free(func_name);
    g_assert(msg != NULL);

    DBusMessageIter iter;
    dbus_message_iter_init_append(msg, &iter);

    for (int i=0; i<argumentCount; i++) {
        if (!js_to_dbus(ctx, arguments[i], 
                    &iter, g_slist_nth_data(sigs_in, i),
                    exception)) {
            g_warning("jsvalue to dbus don't match at pos:%d", i);
            dbus_message_unref(msg);
            return NULL;
        }
    }

    ret = call_sync(ctx, obj_info->connection, msg, sigs_out);

    if (msg != NULL) {
        dbus_message_unref(msg);
    }

    return ret;
}

JSClassRef get_cache_class(struct DBusObjectInfo* obj_info)
{
    return NULL;
}

JSObjectRef get_dynamic_object(
        JSContextRef ctx, DBusGConnection* con,
        const char* server, const char* path, const char* iface)
{
    struct DBusObjectInfo* obj_info =
        get_build_object_info(con, server, path, iface);

    obj_info->connection = dbus_g_connection_get_connection(con);

    JSClassRef class = get_cache_class(obj_info);
    if (class != NULL) {
        return JSObjectMake(ctx, class, obj_info);
    }

    GString *class_name = g_string_new(NULL);
    g_string_printf(class_name, "%s_%s_%s", 
            obj_info->server, obj_info->path, obj_info->iface);

    guint num_of_func = g_hash_table_size(obj_info->methods);
    guint num_of_prop = g_hash_table_size(obj_info->properties);
    guint num_of_signals = g_hash_table_size(obj_info->signals);

    num_of_prop = num_of_signals = 0;

    JSStaticFunction* static_funcs = g_new0(JSStaticFunction, 
            num_of_signals + num_of_func * 2 + 1);
    JSStaticValue* static_values = g_new0(JSStaticValue, num_of_prop + 1);

    GList *names = g_hash_table_get_keys(obj_info->methods);
    for (int i = 0; i < num_of_func; i++) {
        static_funcs[i].name = g_list_nth_data(names, i); 
        static_funcs[i].callAsFunction = dynamic_function;
        static_funcs[i].attributes = kJSPropertyAttributeReadOnly;
    }

    JSClassDefinition class_def = {
        0,
        kJSClassAttributeNone,
        class_name->str,
        NULL,
        static_values, 
        static_funcs,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    };
    g_string_free(class_name, FALSE);

    class = JSClassCreate(&class_def);
    return JSObjectMake(ctx, class, obj_info);
}
