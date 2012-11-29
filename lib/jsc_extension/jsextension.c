/**
 * Copyright (c) 2011 ~ 2012 Deepin, Inc.
 *               2011 ~ 2012 snyh
 *
 * Author:      snyh <snyh@snyh.org>
 * Maintainer:  snyh <snyh@snyh.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, see <http://www.gnu.org/licenses/>.
 **/
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
    JSStringRelease(str);
    if (json == NULL) {
        g_error("This should not appear, please report to the author with the error message: \n  %s \n", data);
        g_assert(json != NULL);
    }
    return json;
}

gboolean jsvalue_instanceof(JSContextRef ctx, JSValueRef test, const char *klass)
{
  JSStringRef property = JSStringCreateWithUTF8CString(klass);
  JSObjectRef ctor = JSValueToObject(ctx,
                         JSObjectGetProperty(ctx, JSContextGetGlobalObject(ctx),
                             property, NULL),
                         NULL);
  JSStringRelease(property);
  return JSValueIsInstanceOfConstructor(ctx, test, ctor, NULL);
}
