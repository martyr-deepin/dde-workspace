#include "dcore.h"
#include <assert.h>
#include <JavaScriptCore/JSStringRef.h>

enum RegionOP {
    REGION_OP_NEW = 0,
    REGION_OP_UNION,
    REGION_OP_INTERSECT,
    REGION_OP_SUBTRACT,
    REGION_OP_XOR,
};

enum RegionType {
    REGION_TMP = 0,
    REGION_GLOBAL,
};


static void apply_region(struct DDesktopData* data)
{
    GtkWidget* widget = data->webview;
    GdkWindow *window = gtk_widget_get_window(gtk_widget_get_toplevel(widget));
    cairo_region_t *region = cairo_region_create();
    cairo_region_union(region, data->tmp_region);
    cairo_region_union(region, data->global_region);
    gdk_window_shape_combine_region(window, region, 0, 0);
}

static 
void update_region(int type, const cairo_rectangle_int_t *rect, int op, JSObjectRef this)
{
    struct DDesktopData *data = JSObjectGetPrivate(this);
    if (op == REGION_OP_NEW && type == REGION_TMP) {
        //TODO: gobject auto free?
        /*data->tmp_region = gdk_region_rectangle(rect);*/
        data->tmp_region = cairo_region_create_rectangle(rect);
        apply_region(data);
        return;
    } else if (op == REGION_OP_NEW && type == REGION_GLOBAL) {
        /*data->global_region = gdk_region_rectangle(rect);*/
        data->global_region = cairo_region_create_rectangle(rect);
        apply_region(data);
        return;
    }

    /*GdkRegion *tmp_region = data->tmp_region;
    GdkRegion *global_region = data->global_region;
    GdkRegion *region = NULL;*/

    cairo_region_t *tmp_region = data->tmp_region;
    cairo_region_t *global_region = data->global_region;
    cairo_region_t *region = NULL;

    if (type == REGION_TMP)
        region = tmp_region;
    else
        region = global_region;

    switch (op) {
        case REGION_OP_UNION:
            /*gdk_region_union_with_rect(region, rect);*/
            cairo_region_union_rectangle(region, rect);
            break;
        case REGION_OP_INTERSECT:
            /*gdk_region_intersect(region, gdk_region_rectangle(rect));*/
            cairo_region_intersect_rectangle(region, rect);
            break;
        case REGION_OP_SUBTRACT:
            /*gdk_region_subtract(region, gdk_region_rectangle(rect));*/
            cairo_region_subtract_rectangle(region, rect);
            break;
        case REGION_OP_XOR:
            /*gdk_region_xor(region, gdk_region_rectangle(rect));*/
            cairo_region_xor_rectangle(region, rect);
            break;
        default:
            assert(!"this operation hasn't support!");
    }
    if (type == REGION_TMP)
        data->tmp_region = region;
    else
        data->global_region = region;
    apply_region(data);
}

static JSValueRef modify_region(JSContextRef context,
        JSObjectRef function, JSObjectRef thisObject,
        size_t argumentCount, const JSValueRef arguments[],
        JSValueRef *exception)
{
    if (argumentCount != 6) {
        puts("must 6 arguments\n");
        return JSValueMakeNull(context);
    }
    int type = JSValueToNumber(context, arguments[0], NULL);
    int op = JSValueToNumber(context, arguments[1], NULL);
    int x = JSValueToNumber(context, arguments[2], NULL);
    int y = JSValueToNumber(context, arguments[3], NULL);
    int width = JSValueToNumber(context, arguments[4], NULL);
    int height = JSValueToNumber(context, arguments[5], NULL);
    /*GdkRectangle rect = {x, y, width, height};*/
    cairo_rectangle_int_t rect = {x, y, width, height};
    update_region(type, &rect, op, thisObject);

    return JSValueMakeNull(context);
}

static const JSStaticFunction class_staticfuncs[] = {
    { "modify_region", modify_region, kJSPropertyAttributeReadOnly },

    /*{ "tray_add_cb", set_default_region, kJSPropertyAttributeReadOnly},
    { "tray_del_cb", set_default_region, kJSPropertyAttributeReadOnly},*/

    { NULL, NULL, 0}
};

static const JSClassDefinition class_def = {
    0, 
    kJSClassAttributeNone,
    "DCoreClass",
    NULL,
    NULL, //class_staticvalues,
    class_staticfuncs,
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
//inline
JSClassRef get_ddesktop_class()
{
    static JSClassRef _ddesktop_class = NULL;
    if (_ddesktop_class == NULL) {
        _ddesktop_class = JSClassCreate(&class_def);
    }
    return _ddesktop_class;
}
void init_ddesktop(JSGlobalContextRef context, struct DDesktopData* data)
{
    JSObjectRef class_obj = JSObjectMake(context, get_ddesktop_class(), (void*)data);
    JSObjectRef global_obj = JSContextGetGlobalObject(context);
    JSStringRef str = JSStringCreateWithUTF8CString("DCore");
    JSObjectSetProperty(context, global_obj, str, class_obj,
            kJSClassAttributeNone, NULL);
}
