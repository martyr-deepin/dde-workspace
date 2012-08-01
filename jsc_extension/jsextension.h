#ifndef __JS_EXTENSION__
#define __JS_EXTENSION__
#include <JavaScriptCore/JSContextRef.h>

#define FILL_EXCEPTION(excp, str) do { \
        JSStringRef string = JSStringCreateWithUTF8CString(#str); \
        JSValueRef exc_str = JSValueMakeString(ctx, string); \
        JSStringRelease(string); \
        *excp= JSValueToObject(ctx, exc_str, NULL); \
} while (0)

typedef struct JSData {
    JSContextRef ctx;
    JSValueRef* exception;
    void* webview;
} JSData;

void init_js_extension(JSGlobalContextRef context, void* webview);

void destroy_js_extension();

JSGlobalContextRef get_global_context();


#endif


