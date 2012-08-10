#ifndef __JS_EXTENSION__
#define __JS_EXTENSION__
#include <JavaScriptCore/JavaScript.h>

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


#endif


