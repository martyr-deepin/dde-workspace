#include <JavaScriptCore/JSObjectRef.h>
#include <JavaScriptCore/JSStringRef.h>
#include <string.h>
#include <glib.h>
#include <gio/gio.h>

#include "utils.h"
#include "dbus_introspect.h"
#include "dbus_object_info.h"
#include "dbus_js_convert.h"
#include "jsextension.h"

void dbus_object_info_free(struct DBusObjectInfo* info);

static GHashTable *__sig_info_hash = NULL; // hash of (path:ifc:sig_name  ---> (hash of callbackid---> *SignalInfo))
static GHashTable *__objs_cache = NULL;

void reset_dbus_infos()
{
    if (__sig_info_hash) {
        g_hash_table_remove_all(__sig_info_hash);
    }
    if (__objs_cache) {
        g_hash_table_remove_all(__objs_cache);
    }
}

typedef int SIGNAL_CALLBACK_ID;

struct SignalInfo {
    const char* name;
    GSList* signatures;
    const char* path;
    const char* iface;
    JSObjectRef callback;
};
struct AsyncInfo {
    JSObjectRef on_ok;
    JSObjectRef on_error;
    GDBusConnection* connection;
};

struct ObjCacheKey {
    GDBusConnection* connection;
    const char* bus_name;
    const char* path;
    const char* iface;
};

guint key_hash(struct ObjCacheKey* key)
{
    return g_str_hash(key->bus_name) + g_str_hash(key->path) +
        g_str_hash(key->iface) + g_direct_hash(key->connection);
}

guint key_equal(struct ObjCacheKey* a, struct ObjCacheKey* b)
{
    char* a_str = g_strdup_printf("%s%s%s%p",
            a->bus_name, a->path, a->iface, a->connection);
    char* b_str = g_strdup_printf("%s%s%s%p",
            b->bus_name, b->path, b->iface, a->connection);
    int ret = g_strcmp0(a_str, b_str);
    g_free(a_str);
    g_free(b_str);
    return ret;
}

void handle_signal_callback(gpointer no_used_key, struct SignalInfo* info, GDBusMessage *msg)
{
    NOUSED(no_used_key);
    g_assert(info->callback != NULL);

    GVariant* body = g_dbus_message_get_body(msg);
    if (body == NULL) {
	JSObjectCallAsFunction(get_global_context(), info->callback, NULL, 0, NULL, NULL);
    } else {
	int num = g_slist_length(info->signatures);
	if (num != g_variant_n_children(body)) {
	    return;
	}

	JSValueRef *params = g_new(JSValueRef, num);
	for (int i=0; i<num; i++) {
	    GVariant* item = g_variant_get_child_value(body, i);
	    params[i] = dbus_to_js(get_global_context(), item);
	    g_variant_unref(item);
	}

	JSObjectCallAsFunction(get_global_context(), info->callback, NULL, num, params, NULL);

	g_free(params);
    }
}

GDBusMessage* watch_signal(GDBusConnection* connection, GDBusMessage *msg, gboolean incoming, gpointer *no_use)
{
    NOUSED(no_use);
    if (g_dbus_message_get_message_type(msg)  != G_DBUS_MESSAGE_TYPE_SIGNAL) {
	return msg;
    }

    if (__sig_info_hash == NULL)
        return msg;


    const char* iface = g_dbus_message_get_interface(msg);
    const char* s_name = g_dbus_message_get_member(msg);
    const char* path = g_dbus_message_get_path(msg);

    char* key = g_strdup_printf("%s:%s:%s@%s", path, iface, s_name, g_dbus_connection_get_unique_name(connection));
    GHashTable* cbs_info  = g_hash_table_lookup(__sig_info_hash, key);
    g_free(key);

    if (cbs_info == NULL) {
	return msg;
    } else {
	g_hash_table_foreach(cbs_info, (GHFunc)handle_signal_callback, msg);
	return msg;
    }
}


PRIVATE void signal_info_free(struct SignalInfo* sig_info)
{
    g_assert(sig_info != NULL);
    if (sig_info->callback) {
        JSValueUnprotect(get_global_context(), sig_info->callback);
    }
    g_free(sig_info);
}

SIGNAL_CALLBACK_ID add_signal_callback(JSContextRef ctx, struct DBusObjectInfo *info,
        struct Signal *sig, JSObjectRef func)
{
    g_assert(sig != NULL);
    g_assert(func != NULL);

    if (__sig_info_hash == NULL) {
        __sig_info_hash = g_hash_table_new_full(g_str_hash, g_str_equal, NULL, (GDestroyNotify)g_hash_table_destroy);
    }

    char* key = g_strdup_printf("%s:%s:%s@%s", info->path, info->iface, sig->name, g_dbus_connection_get_unique_name(info->connection));

    GHashTable *cbs = g_hash_table_lookup(__sig_info_hash, key);
    if (cbs == NULL) {
	cbs = g_hash_table_new_full(g_direct_hash, g_direct_equal, NULL, (GDestroyNotify)signal_info_free);
	g_hash_table_insert(__sig_info_hash, key, cbs);
    }

    struct SignalInfo* sig_info = g_new0(struct SignalInfo, 1);
    sig_info->name = sig->name;
    sig_info->signatures = sig->signature;
    sig_info->path = info->path;
    sig_info->iface = info->iface;
    sig_info->callback = func;
    JSValueProtect(ctx, func);

    SIGNAL_CALLBACK_ID id = (SIGNAL_CALLBACK_ID)GPOINTER_TO_INT(func);
    g_hash_table_insert(cbs, GINT_TO_POINTER((int)id), sig_info);
    return id;
}



static
JSValueRef signal_connect(JSContextRef ctx,
                            JSObjectRef function,
                            JSObjectRef this,
                            size_t argumentCount,
                            const JSValueRef arguments[],
                            JSValueRef *exception)
{
    NOUSED(function);
    if (argumentCount != 2 ) {
        js_fill_exception(ctx, exception, "connect must have two params");
        return NULL;
    }
    struct DBusObjectInfo* obj_info = JSObjectGetPrivate(this);

    if (!JSValueIsString(ctx, arguments[0])) {
        js_fill_exception(ctx, exception, "the first params must the signal name");
        return NULL;
    }

    char* s_name = jsvalue_to_cstr(ctx, arguments[0]);
    struct Signal *signal = g_hash_table_lookup(obj_info->signals, s_name);
    if (signal == NULL) {
        js_fill_exception(ctx, exception, "the interface hasn't this signal");
        return NULL;
    }
    g_free(s_name);


    JSObjectRef callback = JSValueToObject(ctx, arguments[1], NULL);
    if (!JSObjectIsFunction(ctx, callback)) {
        js_fill_exception(ctx, exception, "the params two must be an function!");
        return NULL;
    }

    SIGNAL_CALLBACK_ID id = add_signal_callback(ctx, obj_info, signal, callback);
    if (id == -1) {
        js_fill_exception(ctx, exception, "you have aleady watch the signal with this callback?");
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
    NOUSED(function);
    struct DBusObjectInfo* info = JSObjectGetPrivate(this);

    if (argumentCount != 2) {
	js_fill_exception(ctx, exception, "Disconnet_signal need tow paramters!");
    }

    char* sig_name = jsvalue_to_cstr(ctx, arguments[0]);
    char* key = g_strdup_printf("%s%s%s", info->path, info->iface, sig_name);
    g_free(sig_name);
    GHashTable *cbs = g_hash_table_lookup(__sig_info_hash, key);
    g_free(key);

    if (cbs == NULL) {
	js_fill_exception(ctx, exception, "This signal hasn't connected!");
	return NULL;
    }
    SIGNAL_CALLBACK_ID cb_id = (SIGNAL_CALLBACK_ID)(int)JSValueToNumber(ctx, arguments[1], NULL);
    if (!g_hash_table_remove(cbs, GINT_TO_POINTER(cb_id))) {
	js_fill_exception(ctx, exception, "This signal hasn't connected!");
	return NULL;
    }

    return JSValueMakeNull(ctx);
}
static
JSValueRef signal_emit(JSContextRef ctx,
                            JSObjectRef function,
                            JSObjectRef this,
                            size_t argumentCount,
                            const JSValueRef arguments[],
                            JSValueRef *exception)
{
    NOUSED(function);
    NOUSED(this);
    NOUSED(argumentCount);
    NOUSED(arguments);
    /*obj_info;*/
    /*signal_name;*/
    /*signal_signature;*/
    /*arguments;*/
    js_fill_exception(ctx, exception, "Not Implement signal emit");
    return NULL;
}


void async_info_free(struct AsyncInfo* info)
{
    if (info->on_error) {
        JSValueUnprotect(get_global_context(), info->on_error);
    }
    if (info->on_ok) {
        JSValueUnprotect(get_global_context(), info->on_ok);
    }
    g_free(info);
}

void async_callback(GObject *source, GAsyncResult* res, struct AsyncInfo *info)
{
    GError* error = NULL;
    GVariant* r = g_dbus_connection_call_finish(info->connection, res, &error);
    if (error != NULL) {
	if (info->on_error != NULL)
	    JSObjectCallAsFunction(get_global_context(), info->on_error, NULL, 0, NULL, NULL);
	async_info_free(info);
	return;
    } else {
	int num = g_variant_n_children(r);


	JSValueRef *params = g_new(JSValueRef, num);
	for (int i=0; i<num; i++) {
	    GVariant* item = g_variant_get_child_value(r, i);
	    printf("HUHU:%s, %d\n",g_variant_print(item, FALSE), num);
	    params[i] = dbus_to_js(get_global_context(), item);
	    g_variant_unref(item);
	}
	if (info->on_ok)
	    JSObjectCallAsFunction(get_global_context(), info->on_ok, NULL, num, params, NULL);

	g_free(params);
	g_variant_unref(r);
	async_info_free(info);
	return;
    }
}

bool dynamic_set (JSContextRef ctx, JSObjectRef object,
        JSStringRef propertyName, JSValueRef jsvalue, JSValueRef* exception)
{
    struct DBusObjectInfo* obj_info = JSObjectGetPrivate(object);
    GError* error = NULL;

    char* prop_name = jsstring_to_cstr(ctx, propertyName);
    struct Property *p = g_hash_table_lookup(obj_info->properties, prop_name);

    GVariantType* sig = g_variant_type_new(p->signature->data);
    g_dbus_connection_call_sync(obj_info->connection, obj_info->server, obj_info->path, "org.freedesktop.DBus.Properties", "Set", 
	    g_variant_new("(ssv)", obj_info->iface, prop_name, js_to_dbus(ctx, jsvalue, sig, exception)), NULL,
	    G_DBUS_CALL_FLAGS_NONE, -1, NULL, &error);
    g_variant_type_free(sig);
    g_free(prop_name);

    if (error != NULL) {
	char* err_str = g_strdup_printf("synamic_set:%s\n", error->message);
	js_fill_exception(ctx, exception, err_str);
	g_free(err_str);
	g_error_free(error);
	return FALSE;
    }
    return TRUE;
}

JSValueRef dynamic_get (JSContextRef ctx,
        JSObjectRef object, JSStringRef propertyName, JSValueRef* exception)
{
    struct DBusObjectInfo* obj_info = JSObjectGetPrivate(object);
    GError* error = NULL;

    GVariantType* sig_out = g_variant_type_new("(v)");
    char* prop_name = jsstring_to_cstr(ctx, propertyName);

    GVariant * v = g_dbus_connection_call_sync(obj_info->connection, obj_info->server, obj_info->path, "org.freedesktop.DBus.Properties", "Get", 
	    g_variant_new("(ss)", obj_info->iface, prop_name), sig_out,
	    G_DBUS_CALL_FLAGS_NONE, -1, NULL, &error);

    g_free(prop_name);
    g_variant_type_free(sig_out);


    if (error != NULL) {
	char* err_str = g_strdup_printf("dyanmic_get:%s\n", error->message);
	js_fill_exception(ctx, exception, err_str);
	g_free(err_str);
	g_error_free(error);
	return NULL;
    } else {
	GVariant* arg0 = g_variant_get_child_value(v, 0);
	JSValueRef ret = dbus_to_js(ctx,  arg0);
	g_variant_unref(arg0);
	g_variant_unref(v);
	return ret;
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
    gboolean async = TRUE;
    JSObjectRef ok_callback = NULL;
    JSObjectRef error_callback = NULL;

    struct DBusObjectInfo* obj_info = JSObjectGetPrivate(this);

    JSStringRef name_str = JSStringCreateWithUTF8CString("name");
    JSValueRef js_func_name = JSObjectGetProperty(ctx, function, name_str, NULL);
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
	    if (!ok_callback || !JSObjectIsFunction(ctx, ok_callback)) {
		js_fill_exception(ctx, exception, "the parmas's must be the ok callback");
		return NULL;
	    }
	} else if (i == 2) {
	    error_callback = JSValueToObject(ctx, arguments[--argumentCount], NULL);
	    if (!error_callback || !JSObjectIsFunction(ctx, error_callback)) {
		js_fill_exception(ctx, exception, "last parmas's must be the error callback");
		return NULL;
	    }
	    ok_callback = JSValueToObject(ctx, arguments[--argumentCount], NULL);
	    if (!ok_callback || !JSObjectIsFunction(ctx, ok_callback)) {
		js_fill_exception(ctx, exception, "the parmas's must be the ok callback");
		return NULL;
	    }
	} else if (i != 0) {
	    js_fill_exception(ctx, exception, "Signature didn't mached");
	    return NULL;
	}
    } else {
	if (i != 0) {
	    js_fill_exception(ctx, exception, "Signature didn't mached");
	    return NULL;
	}
    }


    GVariant** args = g_new(GVariant*, argumentCount);
    for (guint i=0; i<argumentCount; i++) {
        GVariantType* sig = g_variant_type_new(g_slist_nth_data(sigs_in, i));
	args[i] = js_to_dbus(ctx, arguments[i], sig, exception);
        g_variant_type_free(sig);
	if (args[i] == NULL) {
	    //TODO: Clear
	    g_warning("jsvalue to dbus don't match at pos:%d", i);
	    return NULL;
	}
    }

    GVariantType* sigs_out = gslit_to_varianttype(m->signature_out);
    if (async) {
	ret = JSValueMakeUndefined(ctx);

	struct AsyncInfo *info = g_new0(struct AsyncInfo, 1);
	info->connection = obj_info->connection;
	if (error_callback) {
	    JSValueProtect(get_global_context(), error_callback);
	    info->on_error = error_callback;
	}
	if (ok_callback) {
	    JSValueProtect(get_global_context(), ok_callback);
	    info->on_ok = ok_callback;
	}
	g_dbus_connection_call(obj_info->connection, obj_info->server, obj_info->path, obj_info->iface, func_name, 
		g_variant_new_tuple(args, argumentCount), sigs_out, 
		G_DBUS_CALL_FLAGS_NONE, -1, NULL,
		async_callback, info);
    } else {
	GVariant * v = g_dbus_connection_call_sync(obj_info->connection, obj_info->server, obj_info->path, obj_info->iface, func_name, 
		g_variant_new_tuple(args, argumentCount), sigs_out, 
		G_DBUS_CALL_FLAGS_NONE, -1, NULL, NULL);
	if (g_variant_n_children(v) == 1) {
	    GVariant* arg0 = g_variant_get_child_value(v, 0);
	    ret = dbus_to_js(ctx, arg0);
	    g_variant_unref(arg0);
	} else {
	    ret = dbus_to_js(ctx, v);
	}
	g_variant_unref(v);
    }

    g_free(args);
    g_variant_type_free(sigs_out);
    g_free(func_name);

    return ret;
}

JSClassRef get_cache_class(struct DBusObjectInfo* obj_info)
{
    NOUSED(obj_info);
    //TODO: build cache;
    return NULL;
}

void obj_finalize(JSObjectRef obj)
{
    struct DBusObjectInfo *info = JSObjectGetPrivate(obj);
    g_assert(info != NULL);
}



JSObjectRef build_dbus_object(JSContextRef ctx, struct ObjCacheKey *key)
{
    struct DBusObjectInfo* obj_info = build_object_info(key->connection, key->bus_name, key->path, key->iface);

    if (obj_info == NULL) //can't build object info
        return NULL;

    guint num_of_prop = g_hash_table_size(obj_info->properties);
    g_hash_table_size(obj_info->signals);

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
    for (guint i = 0; i < num_of_prop; i++) {
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
        NULL,//obj_finalize,
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

    obj_info->klass = JSClassCreate(&class_def);

    obj_info->obj = JSObjectMake(ctx, obj_info->klass, obj_info);

    guint num_of_func = g_hash_table_size(obj_info->methods);
    GList *funcs = g_hash_table_get_keys(obj_info->methods);
    for (guint i = 0; i < num_of_func; i++) {
        JSStringRef f_name = JSStringCreateWithUTF8CString(g_list_nth_data(funcs, i));
        JSObjectSetProperty(ctx, obj_info->obj, f_name,
                JSObjectMakeFunctionWithCallback(ctx, f_name, dynamic_function),
                kJSPropertyAttributeReadOnly, NULL);
        JSStringRelease(f_name);


        char* tmp = g_strdup_printf("%s_sync", (char*)g_list_nth_data(funcs, i));
        JSStringRef f_name_sync = JSStringCreateWithUTF8CString(tmp);
        g_free(tmp);
        JSObjectSetProperty(ctx, obj_info->obj, f_name_sync,
                JSObjectMakeFunctionWithCallback(ctx, f_name_sync, dynamic_function),
                kJSPropertyAttributeReadOnly, NULL);
        JSStringRelease(f_name_sync);
    }
    return obj_info->obj;
}

JSObjectRef get_dbus_object(JSContextRef ctx, GDBusConnection* con,
        const char* bus_name, const char* path, const char* iface, JSValueRef exception)
{
    if (bus_name == NULL || path == NULL ||  iface == NULL) {
	char* err_str = g_strdup_printf("can't build dbus object by %s:%s:%s\n", bus_name, path, iface);
        js_fill_exception(ctx, exception, err_str);
	g_free(err_str);
	return NULL;
    }
    if (__objs_cache == NULL) {
        __objs_cache = g_hash_table_new_full(
                (GHashFunc)key_hash,
                (GEqualFunc)key_equal,
                NULL,
                (GDestroyNotify)dbus_object_info_free
                );
    }
    struct ObjCacheKey key;
    key.connection = con;
    key.bus_name = bus_name;
    key.path = path;
    key.iface = iface;

    JSObjectRef obj = g_hash_table_lookup(__objs_cache, &key);
    if (obj == NULL) {
        obj = build_dbus_object(ctx, &key);
	if (obj == NULL) {
	    js_fill_exception(ctx, exception, "can't build_dbus_object");
	}
    }
    return obj;
}
