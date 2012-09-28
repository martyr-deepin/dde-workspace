#include "jsextension.h"
#include <glib.h>

JSValueRef jsvalue_from_cstr(JSContextRef ctx, const char* str)
{
    JSStringRef jsstr = JSStringCreateWithUTF8CString(str);
    JSValueRef r = JSValueMakeString(ctx, jsstr);
    JSStringRelease(jsstr);
    return r;
}

char* jsstring_to_cstr(JSContextRef ctx, JSStringRef js_string)
{
  size_t len = JSStringGetMaximumUTF8CStringSize(js_string);
  char *c_str = g_new(char, len);
  JSStringGetUTF8CString(js_string, c_str, len);
  return c_str;
}

char* jsvalue_to_cstr(JSContextRef ctx, JSValueRef jsvalue)
{
    if (!JSValueIsString(ctx, jsvalue))
    {
        g_warning("Convert an not JSStringRef to string!");
        return NULL;
    }
    JSStringRef js_string = JSValueToStringCopy(ctx, jsvalue, NULL);
    char* cstr = jsstring_to_cstr(ctx, js_string);
    JSStringRelease(js_string);

    return cstr;
}

JSValueRef json_from_cstr(JSContextRef ctx, const char* data)
{
    JSStringRef str = JSStringCreateWithUTF8CString(data);
    JSValueRef json = JSValueMakeFromJSONString(ctx, str);
    printf("json error:%s\n", data);
    JSStringRelease(str);
    g_assert(json != NULL);
    return json;
}
