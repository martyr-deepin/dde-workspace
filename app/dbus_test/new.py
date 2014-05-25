#!/usr/bin/env python2
#-*-coding:utf-8-*-
import gobject
import dbus
import dbus.service
import dbus.mainloop.glib
class DbusText(dbus.service.Object):
    def __init__(self, conn = None, obj_path = "/org/snyh/test", bus_name = "org.snyh.test"):
        dbus.service.Object.__init__(self, conn, obj_path, bus_name)
        self.mainloop = gobject.MainLoop()

    def run(self):
        self.mainloop.run()

    @dbus.service.method("org.snyh.test")
    def quit(self):
        self.mainloop.quit()

    @dbus.service.method("org.snyh.test", in_signature = "v", out_signature = "v")
    def es(self, arg):
        import time
        #raise Warning("")
        time.sleep(2);
        self.t_sig({1:"tttt"}, 10, False)
        return 1

    @dbus.service.signal('org.snyh.test', signature='a{is}ib')
    def t_sig(self, a, b, c):
        print "signal emitted!! with "

if __name__ == "__main__":
    dbus.mainloop.glib.DBusGMainLoop(set_as_default = True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName("org.snyh.test", bus)
    t = DbusText(bus)
    t.run()
