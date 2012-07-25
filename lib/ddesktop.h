#ifndef __DCORE_H___
#define __DCORE_H___
#include <JavaScriptCore/JSContextRef.h>

#define FILL_EXCEPTION(excp, str) do { \
        JSStringRef string = JSStringCreateWithUTF8CString(#str); \
        JSStringRef exc_str = JSValueMakeString(ctx, string); \
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
} JSData;

void init_ddesktop(JSGlobalContextRef context, struct DDesktopData* data);

#endif


