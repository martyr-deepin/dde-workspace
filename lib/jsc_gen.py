JSC_PATH = "jsc_extension/"
modules = []

def register(m):
    modules.append(m);
def generate():
    temp = """
#include "ddesktop.h"
#include <JavaScriptCore/JSStringRef.h>
extern JSClassRef get_Desktop_class();
%(objs_state)s
void init_ddesktop(JSGlobalContextRef context, struct DDesktopData* data)
{
    JSObjectRef global_obj = JSContextGetGlobalObject(context);
    JSObjectRef class_desktop  = JSObjectMake(context, get_Desktop_class(), (void*)data);

    %(objs)s

    JSStringRef str = JSStringCreateWithUTF8CString("Desktop");
    JSObjectSetProperty(context, global_obj, str, class_desktop,
            kJSClassAttributeNone, NULL);
    JSStringRelease(str);
}
"""
    objs = ""
    objs_state = ""
    for m in modules:
        if m.name != "Desktop":
            objs += m.str_install()
            objs_state += "extern JSClassRef get_%s_class();" % m.name
    f = open(JSC_PATH + "init.c", "w")
    f.write(temp % {"objs": objs, "objs_state": objs_state })
    f.close()


class Params:
    def __init__(self, name=None, description=None):
        self.name = name
        self.description = description
    def set_position(self, pos):
        self.position = pos
    def str_clear(self):
        return ""
    def doc(self):
        pass

class Number(Params):
    temp = """
    double p_%(pos)d = JSValueToNumber(context, arguments[%(pos)d], NULL);
"""
    def __init__(self, *args):
        Params.__init__(self, *args)

    def str_init(self):
        return Number.temp % { "pos": self.position }

class String(Params):
    def __init__(self, *args):
        Params.__init__(self, *args)

    temp = """
    JSStringRef value_%(pos)d = JSValueToStringCopy(context, arguments[%(pos)d], NULL);
    size_t size_%(pos)d = JSStringGetMaximumUTF8CStringSize(value_%(pos)d);
    gchar* p_%(pos)d = g_new(gchar, size_%(pos)d);
    JSStringGetUTF8CString(value_%(pos)d, p_%(pos)d, size_%(pos)d);
"""

    temp_clear = """
    g_free(p_%(pos)d);
    JSStringRelease(value_%(pos)d);
"""


    def str_init(self):
        return String.temp % {'pos': self.position}

    def str_clear(self):
        return String.temp_clear % {'pos': self.position}

    def return_value(self):
        return """
    return r;
"""
    def eval_before(self):
        return "gchar* c_return = "
    def eval_after(self):
        return """
    JSStringRef str = JSStringCreateWithUTF8CString(c_return);
    g_free(c_return);
    JSValueRef r = JSValueMakeString(context, str);
    JSStringRelease(str);
"""

class Function:
    temp = """
static JSValueRef __%(name)s__ (JSContextRef context,
                            JSObjectRef function,
                            JSObjectRef thisObject,
                            size_t argumentCount,
                            const JSValueRef arguments[],
                            JSValueRef *exception)
{
    if (argumentCount != %(p_num)d) {return JSValueMakeNull(context);}
    %(params_init)s
    %(func_call)s
    %(params_clear)s
    %(value_return)s
}
"""

    temp_def = """
    { "%(name)s", __%(name)s__, kJSPropertyAttributeReadOnly },
"""

    def __init__(self, name, r_value, *params):
        self.params = params
        self.name = name
        self.r_value = r_value
    def str(self):
        i = 0
        params_init = ""
        params_clear = ""
        for p in self.params:
            p.set_position(i)
            i += 1
            params_init += p.str_init()
            params_clear += p.str_clear()
        return Function.temp % {
                "name" : self.name,
                "p_num" : i,
                "params_init" : params_init,
                "func_call" : self.func_call(),
                "params_clear" : params_clear,
                "value_return" : self.r_value.str(),
                }
    temp_return = """
    void* data = NULL;
    data = JSObjectGetPrivate(thisObject);
    %(return_value)s %(name)s (%(params)s);
    %(eval_after)s
"""
    def func_call(self):
        params_str = []
        for p in self.params:
            params_str.append("p_%d" % p.position)
        params_str.append("data");
        return Function.temp_return % {
                "return_value" : self.r_value.str_eval_before(),
                "eval_after" : self.r_value.str_eval_after(),
                "name": self.name,
                "params" : ', '.join(params_str)
                }
    def str_def(self):
        return Function.temp_def % { "name" : self.name }

class Module:
    temp_class_def = """
#include <JavaScriptCore/JSContextRef.h>
#include <JavaScriptCore/JSStringRef.h>
#include <glib.h>

%(funcs_def)s

static const JSStaticFunction %(name)s_class_staticfuncs[] = {
    %(funcs_state)s
    { NULL, NULL, 0}
};
static const JSClassDefinition %(name)s_class_def = {
    0,
    kJSClassAttributeNone,
    "%(name)sClass",
    NULL,
    NULL, //class_staticvalues,
    %(name)s_class_staticfuncs,
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

JSClassRef get_%(name)s_class()
{
    static JSClassRef _class = NULL;
    if (_class == NULL) {
        _class = JSClassCreate(&%(name)s_class_def);
    }
    return _class;
}
"""

    def __init__(self, name, desc, *args):
        self.name = name
        self.description = desc
        self.funcs = args
        register(self)

    def str(self):
        funcs_def = ""
        funcs_state = ""
        for f in self.funcs:
            funcs_def += f.str()
            funcs_state += f.str_def()
        return Module.temp_class_def % {
                "name" : self.name,
                "funcs_def" : funcs_def,
                "funcs_state" : funcs_state
                }
    def str_install(self):
        temp = """
    JSObjectRef class_%(name)s = JSObjectMake(context, get_%(name)s_class(), (void*)data);
    JSStringRef str_%(name)s = JSStringCreateWithUTF8CString("%(name)s");
    JSObjectSetProperty(context, class_desktop, str_%(name)s, class_%(name)s,
            kJSClassAttributeNone, NULL);
    JSStringRelease(str_%(name)s);
"""
        return temp % {"name" : self.name}

class Return:
    def __init__(self, t):
        if hasattr(t, "__class__"):
            self.type = t
        else:
            self.type = t()
    def str(self):
        return self.type.return_value()
    def str_eval_before(self):
        return self.type.eval_before()
    def str_eval_after(self):
        return self.type.eval_after()

class Null:
    def __call__(self):
        return self
    def return_value(self):
        return "return JSValueMakeNull(context);"
    def eval_before(self):
        return ""
    def eval_after(self):
        return ""

class JSCode(Params):
    def return_value(self):
        return """
    JSValueRef r = JSEvaluateScript(context, scriptJS, NULL, NULL, 1, NULL);
    JSStringRelease(scriptJS);
    return r;
"""
    def eval_before(self):
        return "gchar* c_return = "
    def eval_after(self):
        return """
    JSStringRef scriptJS = JSStringCreateWithUTF8CString(c_return);
    g_free(c_return);
    """
class Data(Params):
    pass

class Description:
    def __init__(self, t):
        pass


import os
for root, dirs, files in os.walk(JSC_PATH):
    for f in files:
        if f.endswith('.cfg'):
            path = os.path.join(root, f)
            path2 = os.path.join(root,  "gen_" + f.rstrip(".cfg") + ".c")
            f = open(path)
            content = f.read()
            try :
                m = eval(content)
            except:
                print "Warnings: format error. (%s)" % path
                f.close()
            else:
                f = open(path2, "w")
                f.write(m.str())
                f.close()

generate()
