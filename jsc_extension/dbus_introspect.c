#include <dbus/dbus.h>
#include <dbus/dbus-glib.h>
#include <JavaScriptCore/JSObjectRef.h>
#include <JavaScriptCore/JSStringRef.h>
#include <glib.h>

#include "dbus_introspect.h"
#include "dbus_object_info.h"
#include "dbus_js_convert.h"
#include "jsextension.h"

#include <stdio.h>

void pp(gpointer data, gpointer user_data)
{
    const char* s = data;
    puts(s);
}

JSValueRef call_sync(JSContextRef ctx, DBusConnection* con, 
        DBusMessage *msg, GSList* sigs_out, JSValueRef* exception)
{
    char *sig  = g_slist_nth_data(sigs_out, 0);

    g_assert(msg != NULL);

    DBusMessage* reply = dbus_connection_send_with_reply_and_block(
            con,
            msg, -1, NULL);
    //TODO: error handle
    //
    
    if (reply == NULL) {
        FILL_EXCEPTION(exception, "dbus daemon faild call this function...");
        return NULL;
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

bool dynamic_set (JSContextRef ctx, JSObjectRef object, 
        JSStringRef propertyName, JSValueRef value, JSValueRef* exception)
{
}

JSValueRef dynamic_get (JSContextRef ctx, 
        JSObjectRef object, JSStringRef propertyName, JSValueRef* exception)
{
    struct DBusObjectInfo* obj_info = JSObjectGetPrivate(object);

    char* prop_name = jsstring_to_cstr(ctx, propertyName);
    struct Property *p = g_hash_table_lookup(obj_info->properties, prop_name);
    g_free(prop_name);

    DBusMessage* msg = dbus_message_new_method_call(
            obj_info->server, 
            obj_info->path, 
            "org.freedesktop.DBus.Properties",
            "Get");
    g_assert(msg != NULL);

    DBusMessageIter iter;
    dbus_message_iter_init_append(msg, &iter);

    JSStringRef iface = JSStringCreateWithUTF8CString(obj_info->iface);
    if (!js_to_dbus(ctx, JSValueMakeString(ctx, iface), &iter, "s", exception)) {
        dbus_message_unref(msg);
        return NULL;
    }
    JSStringRelease(iface);

    if (!js_to_dbus(ctx, JSValueMakeString(ctx, propertyName), &iter, "s", exception)) {
        dbus_message_unref(msg);
        return NULL;
    }

    return call_sync(ctx, obj_info->connection, msg, p->signature, exception);
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

    ret = call_sync(ctx, obj_info->connection, msg, sigs_out, exception);

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

    if (obj_info == NULL) //can't build object info
        return NULL;

    JSClassRef class = get_cache_class(obj_info);
    if (class != NULL) {
        return JSObjectMake(ctx, class, obj_info);
    }


    guint num_of_prop = g_hash_table_size(obj_info->properties);
    guint num_of_signals = g_hash_table_size(obj_info->signals);

    // async_funs +  sync_funs + connect + emit + NULL
    JSStaticFunction* static_funcs = g_new0(JSStaticFunction, 3);

    JSStaticValue* static_values = g_new0(JSStaticValue, num_of_prop + 1);


    static_funcs[0].name = "connect";
    static_funcs[0].callAsFunction = dynamic_function;
    static_funcs[0].attributes = kJSPropertyAttributeReadOnly;
    static_funcs[1].name = "emit";
    static_funcs[1].callAsFunction = dynamic_function;
    static_funcs[1].attributes = kJSPropertyAttributeReadOnly;

    GList *props = g_hash_table_get_keys(obj_info->properties);
    for (int i = 0; i < num_of_prop; i++) {
        const char *p_name = g_list_nth_data(props, i);
        struct Property *prop = g_hash_table_lookup(obj_info->properties, p_name);

        static_values[i].name = prop->name;
        static_values[i].attributes = prop->access;

        //default read write
        if (prop->access == kJSPropertyAttributeNone)  {
            static_values[i].setProperty = dynamic_set;
        }

        static_values[i].getProperty = dynamic_get;
    }

    GString *class_name = g_string_new(NULL);
    g_string_printf(class_name, "%s_%s_%s", 
            obj_info->server, obj_info->path, obj_info->iface);
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

    JSObjectRef obj = JSObjectMake(ctx, class, obj_info);

    guint num_of_func = g_hash_table_size(obj_info->methods);
    GList *funcs = g_hash_table_get_keys(obj_info->methods);
    for (int i = 0; i < num_of_func; i++) {
        JSStringRef f_name = JSStringCreateWithUTF8CString(g_list_nth_data(funcs, i));
        JSObjectSetProperty(ctx, obj, f_name, 
                JSObjectMakeFunctionWithCallback(ctx, f_name, dynamic_function),
                kJSPropertyAttributeReadOnly, NULL);
        JSStringRelease(f_name);
    }
    return obj;
}
