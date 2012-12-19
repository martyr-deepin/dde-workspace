#include "jsextension.h"
#include <glib-object.h>

struct _ObjectData {
    long id;
    void* core;
    NObjectRef ref;
    NObjectUnref unref;
};

static
void object_init(JSContextRef ctx, JSObjectRef object)
{
    struct _ObjectData* data = JSObjectGetPrivate(object);
    g_assert(data != NULL);
    if (data->ref) {
        data->ref(data->core);
    }
}

static
void object_finlize(JSObjectRef object)
{
    struct _ObjectData* data = JSObjectGetPrivate(object);
    g_assert(data != NULL);
    if (data->unref)
        data->unref(data->core);
    g_free(data);
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

            object_init, 
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

JSObjectRef create_nobject(JSContextRef ctx, void* obj, NObjectRef ref, NObjectUnref unref)
{
    struct _ObjectData* data = g_new(struct _ObjectData, 1);
    data->id = (long)obj;
    data->core = obj;
    data->ref = ref;
    data->unref = unref;
    JSObjectRef r = JSObjectMake(ctx, obj_class(), data);
    return r;
}

void* jsvalue_to_nobject(JSContextRef ctx, JSValueRef value)
{
    if (JSValueIsObjectOfClass(ctx, value, obj_class())) {
        JSObjectRef obj = JSValueToObject(ctx, value, NULL);
        void* core = object_to_core(obj);
        g_assert(core != NULL);
        return core;
    } else {
        g_warning("This JSValueRef is not an DeepinObject!!");
        return NULL;
    }
}
