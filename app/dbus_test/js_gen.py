#!/usr/bin/env python2
#-*-coding:utf-8-*-

import sys

def translate(value):
    v = value.replace("true", "True")
    v = value.replace("false", "False")
    return v

temp = """
window.test = Desktop.DBus.session_object("orz.test", "/orz/test", "orz.test")
%(methods)s
"""
temp_func = """
var ret = test.%(func_name)s(%(func_arg)s);
if (ret != %(func_ret)s) {
    console.log("%(func_name)s ERROR")
}
"""

f = open(sys.argv[1], "r")
methods = ""
for line in f.readlines():
    fields = line.split()
    methods += temp_func % {
            "func_name": fields[0],
            "func_arg": fields[-2],
            "func_ret": fields[-1]
            }

print temp % {"methods": methods}
