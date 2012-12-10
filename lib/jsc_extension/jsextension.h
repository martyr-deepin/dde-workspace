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
#ifndef __JS_EXTENSION__
#define __JS_EXTENSION__
#include <JavaScriptCore/JavaScript.h>
#include <glib.h>

#define JS_EXPORT_API

typedef struct JSData {
    JSContextRef ctx;
    JSValueRef* exception;
    void* webview;
} JSData;

void init_js_extension(JSGlobalContextRef context, void* webview);
void destroy_js_extension();


/*  utils function *  */

#define FILL_EXCEPTION(ctx, excp, str) do { \
        JSStringRef string = JSStringCreateWithUTF8CString(#str); \
        JSValueRef exc_str = JSValueMakeString(ctx, string); \
        JSStringRelease(string); \
        *excp= JSValueToObject(ctx, exc_str, NULL); \
} while (0)

JSGlobalContextRef get_global_context();

JSValueRef jsvalue_null();

JSValueRef jsvalue_from_cstr(JSContextRef, const char* str);
JSValueRef json_from_cstr(JSContextRef, const char* json_str);
char* jsvalue_to_cstr(JSContextRef, JSValueRef);
char* jsstring_to_cstr(JSContextRef, JSStringRef);

typedef void (*NObjFreeFunc)(void*);

JSObjectRef create_nobject(JSContextRef ctx, void* obj, NObjFreeFunc func);

void* jsvalue_to_nobject(JSContextRef, JSValueRef);

gboolean jsvalue_instanceof(JSContextRef ctx, JSValueRef test, const char *klass);

void js_post_message(const char* name, const char* format, ...);
void js_post_message_json(const char* name, JSValueRef json);

JSObjectRef json_create();
void json_append_value(JSObjectRef json, const char* key, JSValueRef value);
void json_append_string(JSObjectRef json, const char* key, const char* value);
void json_append_number(JSObjectRef json, const char* key, double value);
void json_append_nobject(JSObjectRef json, const char* key, void* value, NObjFreeFunc func);

JSObjectRef json_array_create();
void json_array_append(JSObjectRef json, gsize i, JSValueRef value);



#endif


