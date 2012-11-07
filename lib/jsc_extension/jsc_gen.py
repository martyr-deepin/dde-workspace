#!/usr/bin/python2

#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#Maintainer:  snyh <snyh@snyh.org>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.

import sys
JSC_PATH = sys.argv[1]

try:
    import os
    os.mkdir(JSC_PATH + "/gen")
except:
    pass

modules = []


def register(m):
    if m.up_class.name != "DCore" and modules.count(m.up_class) == 0:
        modules.append(m.up_class)
    modules.append(m);

def generate():
    temp = """
#include "jsextension.h"
#include <JavaScriptCore/JSStringRef.h>
extern JSClassRef get_DCore_class();
%(objs_state)s
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

    %(objs)s

    JSStringRef str = JSStringCreateWithUTF8CString("DCore");
    JSObjectSetProperty(context, global_obj, str, class_DCore,
            kJSClassAttributeNone, NULL);
    JSStringRelease(str);
}
"""
    objs = ""
    objs_state = ""
    modules.reverse()
    for m in modules:
        if m.name != "DCore":
            objs += m.str_install()
            objs_state += "extern JSClassRef get_%s_class();\n" % m.name
    f = open(JSC_PATH + "/init.c", "w")
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

class Property:
    def __init__(self, *args):
        self.properties = args
    def str(self):
        tmp = """
JSValueRef %(set_func)s (JSContextRef ctx, JSObjectRef obj,
                JSStringRef prop_name, JSValueRef* exception)
{
}
"""
        return tmp


class Number(Params):
    temp = """
    double p_%(pos)d = JSValueToNumber(context, arguments[%(pos)d], NULL);
"""
    def __init__(self, *args):
        Params.__init__(self, *args)

    def str_init(self):
        return Number.temp % { "pos": self.position }
    def raw(self):
        return "double "

    def eval_before(self):
        return "double ret = "
    def eval_after(self):
        return ""
    def return_value(self):
        return "return JSValueMakeNumber(context, ret);"
class Boolean(Params):
    def __init__(self, *args):
        Params.__init__(self, *args)
    def str_init(self):
        return "bool p_%(pos)d = JSValueToBoolean(context, arguments[%(pos)d]);" % {"pos": self.position}
    def raw(self):
        return "bool "

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

    def raw(self):
        return "char * "

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

    JSValueRef r = NULL;
    if (c_return != NULL) {
        JSStringRef str = JSStringCreateWithUTF8CString(c_return);
        g_free(c_return);
        r = JSValueMakeString(context, str);
        JSStringRelease(str);
    } else {
        FILL_EXCEPTION(context, exception, "the return string is NULL");
    }
"""

class Signal:
    def __init__(self, *params):
        pass

class Function:
    temp = """
extern %(raw_return)s %(name)s(%(raw_params)s);
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
        raw_params = []
        for p in self.params:
            p.set_position(i)
            i += 1
            params_init += p.str_init()
            params_clear += p.str_clear()
            raw_params.append(p.raw())
        raw_params.append("JSData*")
        return Function.temp % {
                "raw_return" : self.r_value.raw(),
                "raw_params" : ', '.join(raw_params),
                "name" : self.name,
                "p_num" : i,
                "params_init" : params_init,
                "func_call" : self.func_call(),
                "params_clear" : params_clear,
                "value_return" : self.r_value.return_value(),
                }
    temp_return = """
    JSData* data = g_new0(JSData, 1);
    data->ctx = context;
    data->exception = exception;
    data->webview = get_global_webview();
    %(return_value)s %(name)s (%(params)s);
    %(eval_after)s
    g_free(data);
"""
    def func_call(self):
        params_str = []
        for p in self.params:
            params_str.append("p_%d" % p.position)
        params_str.append("data");
        return Function.temp_return % {
                "return_value" : self.r_value.eval_before(),
                "eval_after" : self.r_value.eval_after(),
                "name": self.name,
                "params" : ', '.join(params_str)
                }
    def str_def(self):
        return Function.temp_def % { "name" : self.name }

class Class:
    temp_class_def = """
#include <JavaScriptCore/JSContextRef.h>
#include <JavaScriptCore/JSStringRef.h>
#include "jsextension.h"
#include <glib.h>

extern void* get_global_webview();

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

    def __init__(self, name, desc=None, *args):
        self.name = name
        self.description = desc
        self.funcs = []
        self.values = []
        self.child_modules = []



        for arg in args:
            if isinstance(arg, Function):
                self.funcs.append(arg)
            elif isinstance(arg, Value):
                self.values.append(arg)
            elif isinstance(arg, Class):
                arg.up_class = self
                arg.name = arg.up_class.name + "_" + arg.name
                self.child_modules.append(arg)

        class PseudoMoudle:
            name = "DCore"
        if not hasattr(self, "up_class"):
            self.up_class = PseudoMoudle

        register(self)


    def str(self):
        funcs_def = ""
        funcs_state = ""
        for f in self.funcs:
            funcs_def += f.str()
            funcs_state += f.str_def()
        contents = Class.temp_class_def % {
                "name" : self.name,
                "funcs_def" : funcs_def,
                "funcs_state" : funcs_state
                }

        for m in self.child_modules:
            contents += m.str()

        return contents;

    def str_install(self):
        temp = """
    JSObjectRef class_%(name)s = JSObjectMake(context, get_%(name)s_class(), NULL);
    JSStringRef str_%(name)s = JSStringCreateWithUTF8CString("%(name)s");
    JSObjectSetProperty(context, class_%(up_class)s, str_%(name)s, class_%(name)s,
            kJSClassAttributeNone, NULL);
    JSStringRelease(str_%(name)s);
"""
        return temp % {"name" : self.name, "up_class" : self.up_class.name}

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
    def raw(self):
        return "void"
    def return_value(self):
        return "return JSValueMakeNull(context);"
    def eval_before(self):
        return ""
    def eval_after(self):
        return ""

class JSCode(Params):
    def return_value(self):
        return """
    JSValueRef r = JSValueMakeFromJSONString(context, scriptJS);
    if (r == NULL)
        FILL_EXCEPTION(context, exception, "JSON Data Error");
    JSStringRelease(scriptJS);
    JSGarbageCollect(context); //JSC1.8 can't auto free this json object. 
    return r;
"""
    def raw(self):
        return "char *";
    def eval_before(self):
        return "gchar* c_return = "
    def eval_after(self):
        return """
    JSStringRef scriptJS = JSStringCreateWithUTF8CString(c_return);
    g_free(c_return);
    """

class JSValue(Params):
    def __init__(self, *args):
        Params.__init__(self, *args)
    def raw(self):
        return "JSValueRef "
    def str_init(self):
        return "JSValueRef p_%(pos)d = arguments[%(pos)d];\n" % {"pos":self.position}
    def eval_before(self):
        return "JSValueRef c_return = "
    def eval_after(self):
        return ""
    def return_value(self):
        return "return c_return;"

class Data(Params):
    pass

class Description:
    def __init__(self, t):
        pass

class Value:
    def __init__(self, name):
        pass


import os
for root, dirs, files in os.walk(JSC_PATH):
    for f in files:
        if f.endswith('.cfg'):
            path = os.path.join(root, f)
            path2 = os.path.join(root,  "gen/gen_" + f.rstrip(".cfg") + ".c")
            f = open(path)
            content = f.read()
            try :
                m = eval(content)
            except:
                print "Warnings: format error. (%s)" % path
                f.close()
                raise
            else:
                f = open(path2, "w")
                f.write(m.str())
                f.close()

if len(sys.argv) != 3:
    generate()
