
#include "ddesktop.h"
#include <JavaScriptCore/JSStringRef.h>
extern JSClassRef get_Desktop_class();
extern JSClassRef get_Core_class();
void init_ddesktop(JSGlobalContextRef context, struct DDesktopData* data)
{
    JSObjectRef global_obj = JSContextGetGlobalObject(context);
    JSObjectRef class_desktop  = JSObjectMake(context, get_Desktop_class(), (void*)data);

    
    JSObjectRef class_Core = JSObjectMake(context, get_Core_class(), (void*)data);
    JSStringRef str_Core = JSStringCreateWithUTF8CString("Core");
    JSObjectSetProperty(context, class_desktop, str_Core, class_Core,
            kJSClassAttributeNone, NULL);
    JSStringRelease(str_Core);


    JSStringRef str = JSStringCreateWithUTF8CString("Desktop");
    JSObjectSetProperty(context, global_obj, str, class_desktop,
            kJSClassAttributeNone, NULL);
    JSStringRelease(str);
}
