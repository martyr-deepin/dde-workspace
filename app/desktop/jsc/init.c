
#include "jsextension.h"
#include <JavaScriptCore/JSStringRef.h>
extern JSClassRef get_DCore_class();
extern JSClassRef get_Desktop_class();

JSGlobalContextRef global_ctx = NULL;
void* __webview = NULL;
void* get_global_webview()
{
    return __webview;
}

JSGlobalContextRef get_global_context()
{
    return global_ctx;
}
void init_js_extension(JSGlobalContextRef context, void* webview)
{
    global_ctx = context;
    __webview = webview;
    JSObjectRef global_obj = JSContextGetGlobalObject(context);
    JSObjectRef class_DCore = JSObjectMake(context, get_DCore_class(), NULL);

    
    JSObjectRef class_Desktop = JSObjectMake(context, get_Desktop_class(), NULL);
    JSStringRef str_Desktop = JSStringCreateWithUTF8CString("Desktop");
    JSObjectSetProperty(context, class_DCore, str_Desktop, class_Desktop,
            kJSClassAttributeNone, NULL);
    JSStringRelease(str_Desktop);


    JSStringRef str = JSStringCreateWithUTF8CString("DCore");
    JSObjectSetProperty(context, global_obj, str, class_DCore,
            kJSClassAttributeNone, NULL);
    JSStringRelease(str);
}
