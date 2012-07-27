#ifndef __JS_EXTENSION__
#define __JS_EXTENSION__
#include <JavaScriptCore/JSContextRef.h>

#define FILL_EXCEPTION(excp, str) do { \
        JSStringRef string = JSStringCreateWithUTF8CString(#str); \
        JSValueRef exc_str = JSValueMakeString(ctx, string); \
        JSStringRelease(string); \
        *excp= JSValueToObject(ctx, exc_str, NULL); \
} while (0)

struct DDesktopData {
    void* webview;
    void* global_region;
    void* tmp_region;
};

typedef struct JSData {
    void* priv;
    JSContextRef ctx;
    JSValueRef* exception;
} JSData;

void init_js_extension(JSGlobalContextRef context, struct DDesktopData* data);

void destroy_js_extension();

JSGlobalContextRef get_global_context();


#endif


