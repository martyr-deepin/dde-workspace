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
import os
CFG_FILES = sys.argv[1]
OUTPUT_DIR = os.path.curdir

modules = []


def register(m):
    if m.up_class.name != "DCore" and modules.count(m.up_class) == 0:
        modules.append(m.up_class)
    modules.append(m);



class Params:
    def __init__(self, name=None, description=None):
        self.name = name
        self.description = description
    def set_position(self, pos):
        self.position = pos
    def in_after(self):
        return ""
    def doc(self):
        pass
    def is_array(self):
        return False

    def out_before(self):
        return ""
    def out_after(self):
        return ""

class Array(Params):
    temp = """
    %(type)s* p_%(pos)d_a = NULL;
    int p_%(pos)d_n = 0;

    if (jsvalue_instanceof(context, arguments[%(pos)d], "Array")) {

        JSPropertyNameArrayRef prop_names = JSObjectCopyPropertyNames(context, (JSObjectRef)arguments[%(pos)d]);
        p_%(pos)d_n = JSPropertyNameArrayGetCount(prop_names) - 1;
        JSPropertyNameArrayRelease(prop_names);

        p_%(pos)d_a = g_new0(%(type)s, p_%(pos)d_n);

        for (int i=0; i<p_%(pos)d_n; i++) {
            JSValueRef value = JSObjectGetPropertyAtIndex(context, (JSObjectRef)arguments[%(pos)d], i, NULL);
            p_%(pos)d_a[i] = %(element_alloc)s;
        }

    }
"""
    def is_array(self):
        return True

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

class Object(Params):
    def type(self):
        return "void* "
    def out_before(self, name=None, desc=None, native_type=None, unref=None):
        Params.__init__(self, name, desc)
        self.unref = unref or "g_object_unref"
        return " void* ret = "
    def return_value(self):
        return "return create_nobject(context, ret, %s);" % self.unref

    def in_before(self):
        return """
    void* p_%(pos)d = jsvalue_to_nobject(context, arguments[%(pos)d]);
""" % { "pos": self.position }


class Number(Params):
    temp = """
    double p_%(pos)d = JSValueToNumber(context, arguments[%(pos)d], NULL);
"""
    def in_before(self):
        return Number.temp % { "pos": self.position }
    def type(self):
        return "double "

    def out_before(self):
        return "double ret = "
    def return_value(self):
        return "return JSValueMakeNumber(context, ret);"

class Boolean(Params):
    def in_before(self):
        return """
    bool p_%(pos)d = JSValueToBoolean(context, arguments[%(pos)d]);
"""  % {"pos": self.position}
    def type(self):
        return "gboolean "
    def out_before(self):
        return "gboolean ret = "
    def return_value(self):
        return "return  JSValueMakeBoolean(context, ret);"

class ABoolean(Array):
    def type(self):
        return "gboolean*, int"
    def in_before(self):
        return Array.temp % {'type': 'gboolean', 'pos': self.position, 'element_alloc': "JSValueToBoolean(context, value)"}
    def in_after(self):
        return "g_free(p_%(pos)d_a);" % {'pos': self.position}

class ANumber(Array):
    def type(self):
        return "double*, int"
    def in_before(self):
        return Array.temp % {'type': 'double', 'pos': self.position, 'element_alloc': "JSValueToNumber(context, value, NULL)"}
    def in_after(self):
        return "g_free(p_%(pos)d_a);" % {'pos': self.position}


class AString(Array):
    def type(self):
        return "char **, int"

    def in_before(self):
        return Array.temp % {'type': 'char*', 'pos': self.position, 'element_alloc': "jsvalue_to_cstr(context, value)"}

    def in_after(self):
        temp_clear = """
    for (int i=0; i<p_%(pos)d_n; i++) {
        g_free(p_%(pos)d_a[i]);
    }
    g_free(p_%(pos)d_a);
    """
        return temp_clear % {'pos': self.position}

class String(Params):
    def type(self):
        return "char * "

    def in_before(self):
        temp = """
    gchar* p_%(pos)d = jsvalue_to_cstr(context, arguments[%(pos)d]);
"""
        return temp % {'pos': self.position}

    def in_after(self):
        temp = """
    g_free(p_%(pos)d);
"""
        return temp % {'pos': self.position}

    def return_value(self):
        return """
    return r;
"""
    def out_before(self):
        return "gchar* c_return = "
    def out_after(self):
        return """
    JSValueRef r = NULL;
    if (c_return != NULL) {
        r = jsvalue_from_cstr(context, c_return);
        g_free(c_return);
    } else {
        FILL_EXCEPTION(context, exception, "the return string is NULL");
    }
"""

class CString(String):
    def out_before(self):
        return "const char* c_return = "
    def out_after(self):
        return """
    JSValueRef r = NULL;
    if (c_return != NULL) {
        r = jsvalue_from_cstr(context, c_return);
    } else {
        FILL_EXCEPTION(context, exception, "the return string is NULL");
    }
"""

class Signal:
    def __init__(self, *params):
        pass

class CustomFunc:
    def __init__(self, name):
        self.name = name
    def str_def(self):
        print "huhu"
        return """
    { "%(name)s", %(name)s, kJSPropertyAttributeReadOnly },
""" % { "name" : self.name }
    def str(self):
        return """
extern JSValueRef %(name)s(JSContextRef context,
                        JSObjectRef function,
                        JSObjectRef thisObject,
                        size_t argumentCount,
                        const JSValueRef arguments[],
                        JSValueRef *exception);
""" % { "name" : self.name }


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
            params_init += p.in_before()
            params_clear += p.in_after()
            raw_params.append(p.type())

        raw_params.append("JSData*")
        return Function.temp % {
                "raw_return" : self.r_value.type(),
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
    g_free(data);
    %(out_after)s
"""
    def func_call(self):
        params_str = []
        for p in self.params:
            if p.is_array():
                params_str.append("p_%d_a, p_%d_n" % (p.position, p.position))
            else:
                params_str.append("p_%d" % p.position)
        params_str.append("data");
        return Function.temp_return % {
                "return_value" : self.r_value.out_before(),
                "out_after" : self.r_value.out_after(),
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
#include <glib-object.h>

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
            if isinstance(arg, Function) or isinstance(arg, CustomFunc):
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

class Null(Params):
    def __call__(self):
        return self
    def type(self):
        return "void"
    def return_value(self):
        return "return JSValueMakeNull(context);"

class JSCode(Params):
    def return_value(self):
        return """
    return r;
"""
    def type(self):
        return "char *";

    def out_before(self):
        return "gchar* c_return = "
    def out_after(self):
        return """
    JSValueRef r = NULL;
    if (c_return == NULL) {
        r = JSValueMakeNull(context);
    } else {
        r = json_from_cstr(context, c_return);
        g_free(c_return);
    }
    """

class CJSCode(JSCode):
    def type(self):
        return "const char*";
    def out_before(self):
        return "const gchar* c_return = "
    def out_after(self):
        return """
    JSValueRef r = NULL;
    if (c_return == NULL) {
        r = JSValueMakeNull(context);
    } else {
        r = json_from_cstr(context, c_return);
    }
    """

class JSValueRef(Params):
    def type(self):
        return "JSValueRef "
    def in_before(self):
        return "JSValueRef p_%(pos)d = arguments[%(pos)d];\n" % {"pos":self.position}

    def out_before(self):
        return "JSValueRef c_return = "
    def out_after(self):
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

def gen_init_c():
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
gboolean invoke_js_garbage()
{
    g_debug("invoke js garbage collecte\\n");
    JSGarbageCollect(global_ctx);
    return TRUE;
}
void init_js_extension(JSGlobalContextRef context, void* webview)
{
    if (global_ctx == NULL)
        g_timeout_add_seconds(5, (GSourceFunc)invoke_js_garbage, NULL);
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
    f = open(OUTPUT_DIR + "/init.c", "w")
    f.write(temp % {"objs": objs, "objs_state": objs_state })
    f.close()

def gen_module_c():
    for root, dirs, files in os.walk(CFG_FILES):
        for f in files:
            if f.endswith('.cfg'):
                path = os.path.join(root, f)
                path2 = os.path.join(OUTPUT_DIR,  "gen_" + f.rstrip(".cfg") + ".c")
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


gen_module_c()

if len(sys.argv) != 3:
    gen_init_c()
