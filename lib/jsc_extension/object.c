#include "jsextension.h"

struct _ObjectData {
    long id;
    void* core;
    UnRefFunc unref;
};

static
void object_finlize(JSObjectRef object)
{
    struct _ObjectData* data = JSObjectGetPrivate(object);
    g_assert(data != NULL);
    if (data->unref != NULL)
        data->unref(data->core);
}

static
JSClassRef obj_class()
{
    static JSClassRef objclass = NULL;
    if (objclass == NULL) {
        JSClassDefinition class_def = {
            0,
            kJSClassAttributeNone,
            "DeepinObject",
            NULL,

            NULL, //static value
            NULL, //static function

            NULL,
            object_finlize,
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
        objclass = JSClassCreate(&class_def);
    }
    return objclass;
}



static
void* object_to_core(JSObjectRef object)
{
    struct _ObjectData* data = JSObjectGetPrivate(object);
    if (data == NULL)
        return NULL;
    return data->core;
}

JSObjectRef create_native_object(JSContextRef ctx, void* obj, UnRefFunc unref)
{
    struct _ObjectData* data = g_new(struct _ObjectData, 1);
    data->id = (long)obj;
    data->core = obj;
    data->unref = unref;
    return JSObjectMake(ctx, obj_class(), data);
}

void* jsvalue_to_object(JSContextRef ctx, JSValueRef value)
{
    JSObjectRef obj = JSValueToObject(ctx, value, NULL);
    void* core = object_to_core(obj);
    if (core == NULL) {
        g_warning("This JSValueRef is not an DeepinObject!!");
    }
    return core;

}
