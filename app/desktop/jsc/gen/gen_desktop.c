
#include <JavaScriptCore/JSContextRef.h>
#include <JavaScriptCore/JSStringRef.h>
#include "jsextension.h"
#include <glib.h>

extern void* get_global_webview();


extern void notify_workarea_size(JSData*);
static JSValueRef __notify_workarea_size__ (JSContextRef context,
                            JSObjectRef function,
                            JSObjectRef thisObject,
                            size_t argumentCount,
                            const JSValueRef arguments[],
                            JSValueRef *exception)
{
    if (argumentCount != 0) {return JSValueMakeNull(context);}
    
    
    JSData* data = g_new0(JSData, 1);
    data->ctx = context;
    data->exception = exception;
    data->webview = get_global_webview();
     notify_workarea_size (data);
    
    g_free(data);

    
    return JSValueMakeNull(context);
}

extern char * get_desktop_items(JSData*);
static JSValueRef __get_desktop_items__ (JSContextRef context,
                            JSObjectRef function,
                            JSObjectRef thisObject,
                            size_t argumentCount,
                            const JSValueRef arguments[],
                            JSValueRef *exception)
{
    if (argumentCount != 0) {return JSValueMakeNull(context);}
    
    
    JSData* data = g_new0(JSData, 1);
    data->ctx = context;
    data->exception = exception;
    data->webview = get_global_webview();
    gchar* c_return =  get_desktop_items (data);
    
    JSStringRef scriptJS = JSStringCreateWithUTF8CString(c_return);
    g_free(c_return);
    
    g_free(data);

    
    
    JSValueRef r = JSValueMakeFromJSONString(context, scriptJS);
    if (r == NULL)
        FILL_EXCEPTION(context, exception, "JSON Data Error");
    JSStringRelease(scriptJS);
    return r;

}

extern char *  get_folder_open_icon(JSData*);
static JSValueRef __get_folder_open_icon__ (JSContextRef context,
                            JSObjectRef function,
                            JSObjectRef thisObject,
                            size_t argumentCount,
                            const JSValueRef arguments[],
                            JSValueRef *exception)
{
    if (argumentCount != 0) {return JSValueMakeNull(context);}
    
    
    JSData* data = g_new0(JSData, 1);
    data->ctx = context;
    data->exception = exception;
    data->webview = get_global_webview();
    gchar* c_return =  get_folder_open_icon (data);
    

    JSValueRef r = NULL;
    if (c_return != NULL) {
        JSStringRef str = JSStringCreateWithUTF8CString(c_return);
        g_free(c_return);
        r = JSValueMakeString(context, str);
        JSStringRelease(str);
    } else {
        FILL_EXCEPTION(context, exception, "the return string is NULL");
    }

    g_free(data);

    
    
    return r;

}

extern char *  get_folder_close_icon(JSData*);
static JSValueRef __get_folder_close_icon__ (JSContextRef context,
                            JSObjectRef function,
                            JSObjectRef thisObject,
                            size_t argumentCount,
                            const JSValueRef arguments[],
                            JSValueRef *exception)
{
    if (argumentCount != 0) {return JSValueMakeNull(context);}
    
    
    JSData* data = g_new0(JSData, 1);
    data->ctx = context;
    data->exception = exception;
    data->webview = get_global_webview();
    gchar* c_return =  get_folder_close_icon (data);
    

    JSValueRef r = NULL;
    if (c_return != NULL) {
        JSStringRef str = JSStringCreateWithUTF8CString(c_return);
        g_free(c_return);
        r = JSValueMakeString(context, str);
        JSStringRelease(str);
    } else {
        FILL_EXCEPTION(context, exception, "the return string is NULL");
    }

    g_free(data);

    
    
    return r;

}

extern char *  move_to_desktop(char * , JSData*);
static JSValueRef __move_to_desktop__ (JSContextRef context,
                            JSObjectRef function,
                            JSObjectRef thisObject,
                            size_t argumentCount,
                            const JSValueRef arguments[],
                            JSValueRef *exception)
{
    if (argumentCount != 1) {return JSValueMakeNull(context);}
    
    JSStringRef value_0 = JSValueToStringCopy(context, arguments[0], NULL);
    size_t size_0 = JSStringGetMaximumUTF8CStringSize(value_0);
    gchar* p_0 = g_new(gchar, size_0);
    JSStringGetUTF8CString(value_0, p_0, size_0);

    
    JSData* data = g_new0(JSData, 1);
    data->ctx = context;
    data->exception = exception;
    data->webview = get_global_webview();
    gchar* c_return =  move_to_desktop (p_0, data);
    

    JSValueRef r = NULL;
    if (c_return != NULL) {
        JSStringRef str = JSStringCreateWithUTF8CString(c_return);
        g_free(c_return);
        r = JSValueMakeString(context, str);
        JSStringRelease(str);
    } else {
        FILL_EXCEPTION(context, exception, "the return string is NULL");
    }

    g_free(data);

    
    g_free(p_0);
    JSStringRelease(value_0);

    
    return r;

}


static const JSStaticFunction Desktop_class_staticfuncs[] = {
    
    { "notify_workarea_size", __notify_workarea_size__, kJSPropertyAttributeReadOnly },

    { "get_desktop_items", __get_desktop_items__, kJSPropertyAttributeReadOnly },

    { "get_folder_open_icon", __get_folder_open_icon__, kJSPropertyAttributeReadOnly },

    { "get_folder_close_icon", __get_folder_close_icon__, kJSPropertyAttributeReadOnly },

    { "move_to_desktop", __move_to_desktop__, kJSPropertyAttributeReadOnly },

    { NULL, NULL, 0}
};
static const JSClassDefinition Desktop_class_def = {
    0,
    kJSClassAttributeNone,
    "DesktopClass",
    NULL,
    NULL, //class_staticvalues,
    Desktop_class_staticfuncs,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL,
    NULL
};

JSClassRef get_Desktop_class()
{
    static JSClassRef _class = NULL;
    if (_class == NULL) {
        _class = JSClassCreate(&Desktop_class_def);
    }
    return _class;
}
