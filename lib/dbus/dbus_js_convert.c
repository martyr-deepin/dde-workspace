#include "dbus_js_convert.h"
#include "jsextension.h"

gboolean is_array_key_item(JSContextRef ctx, JSPropertyNameArrayRef array, int index)
{
    //check and filter user defined property(user js defined properties).
    JSStringRef key = JSPropertyNameArrayGetNameAtIndex(array, index);
    char* c_key = jsstring_to_cstr(ctx, key);
    char* endptr = NULL;
    g_ascii_strtoll(c_key, &endptr, 10);
    if (endptr == c_key) {
	return FALSE;
    }
    g_free(c_key);
    return TRUE;
}


GVariant* js_to_dbus(JSContextRef ctx, const JSValueRef jsvalue, const char* sig, JSValueRef *exception)
{
    switch (sig[0]) {
	case 'y':
	    return g_variant_new_byte(JSValueToNumber(ctx, jsvalue, exception));
	case 'n':
	    return g_variant_new_int16(JSValueToNumber(ctx, jsvalue, exception));
	case 'q':
	    return g_variant_new_uint16(JSValueToNumber(ctx, jsvalue, exception));
	case 'i':
	    return g_variant_new_int32(JSValueToNumber(ctx, jsvalue, exception));
	case 'u':
	    return g_variant_new_uint32(JSValueToNumber(ctx, jsvalue, exception));
	case 'x':
	    return g_variant_new_int64(JSValueToNumber(ctx, jsvalue, exception));
	case 't':
	    return g_variant_new_uint64(JSValueToNumber(ctx, jsvalue, exception));
	case 'd':
	    return g_variant_new_double(JSValueToNumber(ctx, jsvalue, exception));
	case 'h':
	    return g_variant_new_handle(JSValueToNumber(ctx, jsvalue, exception));
	case 'b':
	    return g_variant_new_boolean(JSValueToBoolean(ctx, jsvalue));
        case 's':
            {
                char* v = jsvalue_to_cstr(ctx, jsvalue);
                GVariant* r = g_variant_new_string(v);
                g_free(v);
                return r;
            }
	default:
            printf("SSS:%s\n", sig);
	    g_assert_not_reached();
    }
}


static GVariantClass child_type (GVariant* parent)
{
    int n = g_variant_n_children(parent);
    if (n == 0) {
        g_assert_not_reached();
    } else {
        GVariant* c = g_variant_get_child_value(parent, 0);
        GVariantClass r = g_variant_classify(c);
        g_variant_unref(c);
        return r;
    }
}

JSValueRef dbus_to_js(JSContextRef ctx, GVariant *dbus)
{
    JSValueRef jsvalue = NULL;
    GVariantClass type = g_variant_classify(dbus);
    switch (type) {
	case G_VARIANT_CLASS_STRING:	
	case G_VARIANT_CLASS_OBJECT_PATH:
	case G_VARIANT_CLASS_SIGNATURE:
	    {
		JSStringRef js_string = JSStringCreateWithUTF8CString(g_variant_get_string(dbus, NULL));
		jsvalue = JSValueMakeString(ctx, js_string);
		JSStringRelease(js_string);
		return jsvalue;
	    }
	case G_VARIANT_CLASS_BYTE:
	    return JSValueMakeNumber(ctx, g_variant_get_byte(dbus));
	case G_VARIANT_CLASS_DOUBLE:
	    return JSValueMakeNumber(ctx, g_variant_get_double(dbus));
	case G_VARIANT_CLASS_INT16:
	    return JSValueMakeNumber(ctx, g_variant_get_int16(dbus));
	case G_VARIANT_CLASS_UINT16:
	    return JSValueMakeNumber(ctx, g_variant_get_uint16(dbus));
	case G_VARIANT_CLASS_INT32:
	    return JSValueMakeNumber(ctx, g_variant_get_int32(dbus));
	case G_VARIANT_CLASS_UINT32:
	    return JSValueMakeNumber(ctx, g_variant_get_uint32(dbus));
	case G_VARIANT_CLASS_INT64:
	    return JSValueMakeNumber(ctx, g_variant_get_int64(dbus));
	case G_VARIANT_CLASS_UINT64:
	    return JSValueMakeNumber(ctx, g_variant_get_uint64(dbus));
	case G_VARIANT_CLASS_BOOLEAN:
	    return JSValueMakeBoolean(ctx, g_variant_get_boolean(dbus));
	case G_VARIANT_CLASS_HANDLE:
	    g_warning("didn't support FD type");
	    return JSValueMakeNumber(ctx, g_variant_get_uint32(dbus));
	case G_VARIANT_CLASS_VARIANT:
		return dbus_to_js(ctx, g_variant_get_variant(dbus));

	case G_VARIANT_CLASS_DICT_ENTRY:
                g_assert_not_reached();

	case G_VARIANT_CLASS_ARRAY:
            {
                int n = g_variant_n_children(dbus);
                if (n == 0) {
                    return JSObjectMake(ctx, NULL, NULL);
                }
                switch (child_type(dbus)) {
                    case G_VARIANT_CLASS_DICT_ENTRY:
                        {
                            jsvalue = JSObjectMake(ctx, NULL, NULL);
                            for (int i=0; i<n; i++) {
                                GVariant *dic = g_variant_get_child_value(dbus, i);
                                GVariant *key= g_variant_get_child_value (dic, 0);
                                GVariant *value = g_variant_get_child_value (dic, 1);

                                JSValueRef js_key = dbus_to_js(ctx, key);
                                JSValueRef js_value = dbus_to_js(ctx, value);

                                JSStringRef key_str = JSValueToStringCopy(ctx, js_key, NULL);
                                JSObjectSetProperty(ctx, (JSObjectRef)jsvalue, key_str, js_value, 0, NULL);
                                JSStringRelease(key_str);

                                g_variant_unref(key);
                                g_variant_unref(value);
                                g_variant_unref(dic);
                            }
                            return jsvalue;
                        }
                    default:
                        {
                            JSValueRef *args = g_new(JSValueRef, n);
                            for (int i=0; i < n; i++) {
                                args[i] = dbus_to_js(ctx, g_variant_get_child_value(dbus, i));
                            }
                            return JSObjectMakeArray(ctx, n, args, NULL);
                        }
                }
            }
	case G_VARIANT_CLASS_TUPLE:
	    {
                int n = g_variant_n_children(dbus);
                JSValueRef *args = g_new(JSValueRef, n);
                for (int i=0; i < n; i++) {
                    args[i] = dbus_to_js(ctx, g_variant_get_child_value(dbus, i));
                }
                return JSObjectMakeArray(ctx, n, args, NULL);
	    }
    }
    g_warning("didn't support signature type:%c", type);
    return JSValueMakeUndefined(ctx);
}


GVariantType* gslit_to_varianttype(GSList* l)
{
    GString* str = g_string_new("(");
    while (l != NULL) {
        g_string_append(str, l->data);
        l = g_slist_next(l);
    }
    g_string_append(str, ")");
    return g_variant_type_new(g_string_free(str, FALSE));
}
