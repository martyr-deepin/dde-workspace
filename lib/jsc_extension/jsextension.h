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

JSValueRef jsvalue_from_cstr(JSContextRef, const char* str);
JSValueRef json_from_cstr(JSContextRef, const char* data);
char* jsvalue_to_cstr(JSContextRef, JSValueRef);
char* jsstring_to_cstr(JSContextRef, JSStringRef);
gboolean jsvalue_instanceof(JSContextRef ctx, JSValueRef test, const char *klass);

void js_post_message(const char* name, const char* format, ...);

#endif


