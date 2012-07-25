
#include "ddesktop.h"
#include <JavaScriptCore/JSStringRef.h>
extern JSClassRef get_Desktop_class();
extern JSClassRef get_DBus_class();
extern JSClassRef get_DBus_Bus_class();

void init_ddesktop(JSGlobalContextRef context, struct DDesktopData* data)
{
    JSObjectRef global_obj = JSContextGetGlobalObject(context);
    JSObjectRef class_Desktop  = JSObjectMake(context, get_Desktop_class(), (void*)data);

    
    JSObjectRef class_DBus = JSObjectMake(context, get_DBus_class(), (void*)data);
    JSStringRef str_DBus = JSStringCreateWithUTF8CString("DBus");
    JSObjectSetProperty(context, class_Desktop, str_DBus, class_DBus,
            kJSClassAttributeNone, NULL);
    JSStringRelease(str_DBus);

    JSObjectRef class_DBus_Bus = JSObjectMake(context, get_DBus_Bus_class(), (void*)data);
    JSStringRef str_DBus_Bus = JSStringCreateWithUTF8CString("DBus_Bus");
    JSObjectSetProperty(context, class_DBus, str_DBus_Bus, class_DBus_Bus,
            kJSClassAttributeNone, NULL);
    JSStringRelease(str_DBus_Bus);


    JSStringRef str = JSStringCreateWithUTF8CString("Desktop");
    JSObjectSetProperty(context, global_obj, str, class_Desktop,
            kJSClassAttributeNone, NULL);
    JSStringRelease(str);
}
