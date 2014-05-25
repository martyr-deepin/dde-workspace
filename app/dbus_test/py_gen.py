#!/usr/bin/env python2
#-*-coding:utf-8-*-

import sys

def translate(value):
    v = value.replace("true", "True")
    v = value.replace("false", "False")
    return v

if __name__ == "__main__":
    print "#!/usr/bin/env python2"
    print "#-*-coding:utf-8-*-"
    print "import gobject\nimport dbus\nimport dbus.service\nimport dbus.mainloop.glib"

    print "class DbusText(dbus.service.Object):"
    print """    def __init__(self, conn = None, obj_path = "/orz/test", bus_name = "orz.test"):"""
    print """        dbus.service.Object.__init__(self, conn, obj_path, bus_name)"""
    print """        self.mainloop = gobject.MainLoop()"""
    print "\n",
    print """    def run(self):"""
    print """        self.mainloop.run()"""
    print "\n",
    print """    @dbus.service.method("orz.test")"""
    print """    def quit(self):"""
    print """        self.mainloop.quit()"""
    print "\n",

    f = open(sys.argv[1], "r")
    line = f.readline()
    while len(line) > 0:
        src = line.split()
        print """    @dbus.service.method("orz.test", in_signature = "%s", out_signature = "%s")""" % (src[1], src[2])
        print """    def %s(self, arg):""" % src[0]
        print """        return %s""" % translate(src[-1])
        line = f.readline()

    print "\n",
    print """if __name__ == "__main__":"""
    print """    dbus.mainloop.glib.DBusGMainLoop(set_as_default = True)"""
    print """    bus = dbus.SessionBus()"""
    print """    name = dbus.service.BusName("orz.test", bus)"""
    print """    t = DbusText(bus)"""
    print """    t.run()"""
