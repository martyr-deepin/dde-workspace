#!/usr/bin/env python
#-*-coding:utf-8-*-
import gobject
import dbus
import dbus.service
import dbus.mainloop.glib
class DbusText(dbus.service.Object):
    def __init__(self, conn = None, obj_path = "/orz/test", bus_name = "orz.test"):
        dbus.service.Object.__init__(self, conn, obj_path, bus_name)
        self.mainloop = gobject.MainLoop()

    def run(self):
        self.mainloop.run()

    @dbus.service.method("orz.test")
    def quit(self):
        self.mainloop.quit()

    @dbus.service.method("orz.test", in_signature = "v", out_signature = "v")
    def fas(self, arg):
        return 1

if __name__ == "__main__":
    dbus.mainloop.glib.DBusGMainLoop(set_as_default = True)
    bus = dbus.SessionBus()
    name = dbus.service.BusName("orz.test", bus)
    t = DbusText(bus)
    t.run()
