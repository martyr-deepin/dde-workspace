#include "jsextension.h"

JSObjectRef json_create()
{
    return JSObjectMake(get_global_context(), NULL, NULL);
}

void json_append_string(JSObjectRef json, const char* key, const char* value)
{

    JSContextRef ctx = get_global_context();
    JSStringRef js_key = JSStringCreateWithUTF8CString(key);

    JSValueRef js_value = jsvalue_from_cstr(ctx, value);
    JSObjectSetProperty(ctx, json, js_key, js_value, kJSPropertyAttributeNone, NULL);

    JSStringRelease(js_key);
}

void json_append_number(JSObjectRef json, const char* key, double value)
{
    JSContextRef ctx = get_global_context();
    JSStringRef js_key = JSStringCreateWithUTF8CString(key);

    JSObjectSetProperty(ctx, json, js_key, JSValueMakeNumber(ctx, value), kJSPropertyAttributeNone, NULL);

    JSStringRelease(js_key);
}

void json_append_object(JSObjectRef json, const char* key, void* value, UnRefFunc func)
{
    JSContextRef ctx = get_global_context();
    JSStringRef js_key = JSStringCreateWithUTF8CString(key);

    JSObjectRef js_value = create_native_object(ctx, value, func);
    JSObjectSetProperty(ctx, json, js_key, js_value, kJSPropertyAttributeNone, NULL);

    JSStringRelease(js_key);
}

JSValueRef json_from_cstr(JSContextRef ctx, const char* json_str)
{
    JSStringRef str = JSStringCreateWithUTF8CString(json_str);
    JSValueRef json = JSValueMakeFromJSONString(ctx, str);
    JSStringRelease(str);
    if (json == NULL) {
        g_error("This should not appear, please report to the author with the error message: \n  %s \n", json_str);
        g_assert(json != NULL);
    }
    return json;
}
