#include <dbus/dbus.h>
#include <dbus/dbus-glib.h>
#include <JavaScriptCore/JSObjectRef.h>
#include <JavaScriptCore/JSStringRef.h>
#include <glib.h>

#include "dbus_introspect.h"
#include "dbus_object_info.h"
#include "dbus_js_convert.h"
#include "jsextension.h"

static GHashTable *__sig_info_hash; // struct signal -> GSList callback

JSValueRef call_sync(JSContextRef ctx, DBusConnection* con, 
        DBusMessage *msg, GSList* sigs_out, JSValueRef* exception);

struct SignalInfo {
    const char* name;
    GSList* signatures;
    const char* path;
    const char* iface;
    DBusGConnection* con;
    JSObjectRef callback;
    JSContextRef ctx;
};
struct AsyncInfo {
    JSObjectRef on_ok;
    JSObjectRef on_error;
    GSList* signatures;
    JSContextRef ctx;
};


DBusHandlerResult watch_signal(DBusConnection* connection, DBusMessage *msg, 
        void *user_data)
{
    if (dbus_message_get_type(msg) != DBUS_MESSAGE_TYPE_SIGNAL)
        return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;


    const char* iface = dbus_message_get_interface(msg);
    const char* s_name = dbus_message_get_member(msg);
    const char* path = dbus_message_get_path(msg);

    char* key = g_strdup_printf("%s%s%s", path, iface, s_name);
    struct SignalInfo* info = g_hash_table_lookup(__sig_info_hash, key);
    g_free(key);

    if (info == NULL) {
        return DBUS_HANDLER_RESULT_NOT_YET_HANDLED;
    } else {
        DBusMessageIter iter;
        dbus_message_iter_init(msg, &iter);

        int num = g_slist_length(info->signatures);
        JSValueRef *params = g_new(JSValueRef, num);
        for (int i=0; i<num; i++) {
            params[i] = dbus_to_js(info->ctx, &iter);
            if (!dbus_message_iter_next(&iter)) {
            }
        }
        g_assert(info->ctx != NULL);
        g_assert(info->callback != NULL);
        JSValueRef ret = JSObjectCallAsFunction(info->ctx, 
                info->callback, NULL, 
                num, params, NULL);
        g_free(params);

        return DBUS_HANDLER_RESULT_HANDLED;
    }
}

int add_signal_callback(JSContextRef ctx, struct DBusObjectInfo *info, 
        struct Signal *sig, JSObjectRef func)
{
    g_assert(sig != NULL);
    g_assert(func != NULL);

    if (__sig_info_hash == NULL) {
        __sig_info_hash = g_hash_table_new(g_str_hash, g_str_equal);
    }
    char* key = g_strdup_printf("%s%s%s", info->path, info->iface, sig->name);

    GSList *infos = g_hash_table_lookup(__sig_info_hash, key);
    if (infos != NULL) {
        return -1; //alerady has this callback
    }

    struct SignalInfo* sig_info = g_new0(struct SignalInfo, 1);
    sig_info->name = sig->name;
    sig_info->signatures = sig->signature;
    sig_info->path = info->path;
    sig_info->iface = info->iface;
    sig_info->con = dbus_g_connection_get_connection(info->connection);
    sig_info->callback = func;
    sig_info->ctx = get_global_context();

    g_hash_table_insert(__sig_info_hash, key, sig_info);
    return GPOINTER_TO_INT(func);
}



static 
JSValueRef signal_connect(JSContextRef ctx,
                            JSObjectRef function,
                            JSObjectRef this,
                            size_t argumentCount,
                            const JSValueRef arguments[],
                            JSValueRef *exception)
{
    if (argumentCount != 2 ) {
        FILL_EXCEPTION(exception, "connect must have two params");
        return NULL;
    }
    struct DBusObjectInfo* obj_info = JSObjectGetPrivate(this);

    if (__sig_info_hash == NULL) {
        dbus_connection_add_filter(obj_info->connection, watch_signal, NULL, NULL);
    }

    if (!JSValueIsString(ctx, arguments[0])) {
        FILL_EXCEPTION(exception, "the first params must the signal name");
        return NULL;
    }

    char* s_name = jsvalue_to_cstr(ctx, arguments[0]);
    struct Signal *signal = g_hash_table_lookup(obj_info->signals, s_name);
    if (signal == NULL) {
        FILL_EXCEPTION(exception, "the interface hasn't this signal");
        return NULL;
    }


    char* rule = g_strdup_printf("type=signal,interface=%s,member=%s",
            obj_info->iface, s_name);
    dbus_bus_add_match(obj_info->connection, rule, NULL);
    dbus_connection_flush(obj_info->connection);
    g_free(rule);
    g_free(s_name);


    JSObjectRef callback = JSValueToObject(ctx, arguments[1], NULL);
    if (!JSObjectIsFunction(ctx, callback)) {
        FILL_EXCEPTION(exception, "the params two must be an function!");
        return NULL;
    }

    int id = add_signal_callback(ctx, obj_info, signal, callback);
    if (id == -1) {
        FILL_EXCEPTION(exception, "you have aleady watch the signal with this callback?");
        return NULL;
    }

    return JSValueMakeNumber(ctx, id);
}


static 
JSValueRef signal_disconnect(JSContextRef ctx,
                            JSObjectRef function,
                            JSObjectRef this,
                            size_t argumentCount,
                            const JSValueRef arguments[],
                            JSValueRef *exception)
{
    /*obj_info;*/
    /*signal_id;*/
    FILL_EXCEPTION(exception, "Not Implement signal dis_connect");
    return NULL;
}
static 
JSValueRef signal_emit(JSContextRef ctx,
                            JSObjectRef function,
                            JSObjectRef this,
                            size_t argumentCount,
                            const JSValueRef arguments[],
                            JSValueRef *exception)
{
    /*obj_info;*/
    /*signal_name;*/
    /*signal_signature;*/
    /*arguments;*/
    FILL_EXCEPTION(exception, "Not Implement signal emit");
    return NULL;
}

void pp(gpointer data, gpointer user_data)
{
    const char* s = data;
}

void async_callback(DBusPendingCall *pending, void *user_data)
{
    DBusMessage *reply = dbus_pending_call_steal_reply(pending);

    struct AsyncInfo *info = (struct AsyncInfo*) user_data;
    if (dbus_message_get_type(reply) == DBUS_MESSAGE_TYPE_ERROR) {
        if (info->on_error != NULL)
            JSObjectCallAsFunction(info->ctx, info->on_error, NULL, 0, NULL, NULL);
        dbus_message_unref(reply);
        return;
    }

    DBusMessageIter iter;
    dbus_message_iter_init(reply , &iter);

    int num = g_slist_length(info->signatures);
    JSValueRef *params = g_new(JSValueRef, num);
    for (int i=0; i<num; i++) {
        params[i] = dbus_to_js(info->ctx, &iter);
        if (!dbus_message_iter_next(&iter)) {
        }
    }
    dbus_message_unref(reply);
    g_assert(info->ctx != NULL);
    JSObjectCallAsFunction(info->ctx, 
            info->on_ok, NULL, 
            num, params, NULL);
    g_free(params);
}

void call_async(DBusConnection* con, DBusMessage *msg, GSList* sigs_out, 
        JSObjectRef ok_callback, JSObjectRef error_callback)
{
    DBusPendingCall *reply = NULL;
    dbus_connection_send_with_reply(con, msg, &reply, -1);

    struct AsyncInfo *info = g_new0(struct AsyncInfo, 1);
    info->on_error = error_callback;
    info->on_ok = ok_callback;
    info->signatures = sigs_out;
    info->ctx = get_global_context();

    dbus_pending_call_set_notify(reply, async_callback, info, g_free);
    /*dbus_pending_call_unref(reply);*/  //TODO: need this?
}


JSValueRef call_sync(JSContextRef ctx, DBusConnection* con, 
        DBusMessage *msg, GSList* sigs_out, JSValueRef* exception)
{
    char *sig  = g_slist_nth_data(sigs_out, 0);

    g_assert(msg != NULL);
    g_assert(con != NULL);

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
        JSStringRef propertyName, JSValueRef jsvalue, JSValueRef* exception)
{
    struct DBusObjectInfo* obj_info = JSObjectGetPrivate(object);

    char* prop_name = jsstring_to_cstr(ctx, propertyName);
    struct Property *p = g_hash_table_lookup(obj_info->properties, prop_name);
    g_free(prop_name);

    DBusMessage* msg = dbus_message_new_method_call(
            obj_info->server, 
            obj_info->path, 
            "org.freedesktop.DBus.Properties",
            "Set");
    g_assert(msg != NULL);

    DBusMessageIter iter;
    dbus_message_iter_init_append(msg, &iter);

    JSStringRef iface = JSStringCreateWithUTF8CString(obj_info->iface);
    if (!js_to_dbus(ctx, JSValueMakeString(ctx, iface), &iter, "s", exception)) {
        dbus_message_unref(msg);
        return FALSE;
    }
    JSStringRelease(iface);

    if (!js_to_dbus(ctx, JSValueMakeString(ctx, propertyName), &iter, "s", exception)) {
        dbus_message_unref(msg);
        return FALSE;
    }

    DBusMessageIter v_iter;
    dbus_message_iter_open_container(&iter, DBUS_TYPE_VARIANT, 
            g_slist_nth_data(p->signature, 0), &v_iter);
    if (!js_to_dbus(ctx, jsvalue, &v_iter, g_slist_nth_data(p->signature, 0), exception)) {
        dbus_message_unref(msg);
        return FALSE;
    }
    dbus_message_iter_close_container(&iter, &v_iter);

    GSList *tmp = NULL;
    tmp = g_slist_append(tmp, "b");
    if (call_sync(ctx, obj_info->connection, msg, tmp, exception) == NULL) {
        dbus_message_unref(msg);
        g_slist_free(tmp);
        FILL_EXCEPTION(exception, "can't set this property");
        return FALSE;
    } else {
        dbus_message_unref(msg);
        g_slist_free(tmp);
        return TRUE;
    }
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
    gboolean async = TRUE;
    JSObjectRef ok_callback = NULL;
    JSObjectRef error_callback = NULL;

    struct DBusObjectInfo* obj_info = JSObjectGetPrivate(this);

    JSStringRef name_str = JSStringCreateWithUTF8CString("name");
    JSValueRef js_func_name = JSObjectGetProperty(ctx, function, 
            name_str, NULL);
    JSStringRelease(name_str);

    char* func_name = jsvalue_to_cstr(ctx, js_func_name);
    if (g_str_has_suffix(func_name, "_sync")) {
            async = FALSE;
            func_name[strlen(func_name)-5] = '\0';
    }

    struct Method *m = g_hash_table_lookup(obj_info->methods, func_name);
    g_assert(obj_info->methods != NULL);


    GSList* sigs_in = m->signature_in;
    int i = argumentCount - g_slist_length(sigs_in);
    if (async) {
        if (i == 1) {
            ok_callback = JSValueToObject(ctx, arguments[--argumentCount], NULL);
            if (!JSObjectIsFunction(ctx, ok_callback)) {
                FILL_EXCEPTION(exception, "the parmas's must be the ok callback");
                return NULL;
            }
        } else if (i == 2) {
            error_callback = JSValueToObject(ctx, arguments[--argumentCount], NULL);
            if (!JSObjectIsFunction(ctx, error_callback)) {
                FILL_EXCEPTION(exception, "last parmas's must be the error callback");
                return NULL;
            }
            ok_callback = JSValueToObject(ctx, arguments[--argumentCount], NULL);
            if (!JSObjectIsFunction(ctx, ok_callback)) {
                FILL_EXCEPTION(exception, "the parmas's must be the ok callback");
                return NULL;
            }
        } else if (i != 0) {
            FILL_EXCEPTION(exception, "Signature didn't mached");
            return NULL;
        }
    } else {
        if (i != 0) {
            FILL_EXCEPTION(exception, "Signature didn't mached");
            return NULL;
        }
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
    if (async) {
        ret = JSValueMakeUndefined(ctx);
        if (ok_callback != NULL) {
            call_async(obj_info->connection, msg, sigs_out, 
                    ok_callback, error_callback);
        }
    } else {
        ret = call_sync(ctx, obj_info->connection, msg, sigs_out, exception);
    }



    if (msg != NULL) {
        dbus_message_unref(msg);
    }

    return ret;
}

JSClassRef get_cache_class(struct DBusObjectInfo* obj_info)
{
    //TODO: build cache;
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
    JSStaticFunction* static_funcs = g_new0(JSStaticFunction, 4);

    JSStaticValue* static_values = g_new0(JSStaticValue, num_of_prop + 1);


    static_funcs[0].name = "connect";
    static_funcs[0].callAsFunction = signal_connect;
    static_funcs[0].attributes = kJSPropertyAttributeReadOnly;

    static_funcs[1].name = "dis_connect";
    static_funcs[1].callAsFunction = signal_disconnect;
    static_funcs[1].attributes = kJSPropertyAttributeReadOnly;

    static_funcs[2].name = "emit";
    static_funcs[2].callAsFunction = signal_emit;
    static_funcs[2].attributes = kJSPropertyAttributeReadOnly;

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


        char* tmp = g_strdup_printf("%s_sync", g_list_nth_data(funcs, i));
        JSStringRef f_name_sync = JSStringCreateWithUTF8CString(tmp);
        g_free(tmp);
        JSObjectSetProperty(ctx, obj, f_name_sync, 
                JSObjectMakeFunctionWithCallback(ctx, f_name_sync, dynamic_function),
                kJSPropertyAttributeReadOnly, NULL);
        JSStringRelease(f_name_sync);
    }
    return obj;
}
