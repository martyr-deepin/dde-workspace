#!/usr/bin/env python3
from gi.repository import Gtk,GObject
from datetime import datetime
import random

class MainWindow(Gtk.Window):
    def __init__(self):
        Gtk.Window.__init__(self)
        self.set_default_size(400,300)
        vbox = Gtk.Box()
        btn1 = Gtk.Button(label='test dde-dock')
        self.add(vbox)
        vbox.pack_start(btn1,True,True,0)
        self.connect("delete-event",Gtk.main_quit)
        self.set_title_tick_period = 50

        self.set_window_icon_tick_period = 50
        self.set_status_icon_tick_period = 50

        itd = Gtk.IconTheme.get_default()
        icon_names = ('deepin-screenshot','deepin-movie','deepin-terminal','deepin-game-center','deepin-music-player')
        self.status_icon_pixbufs = []
        self.icon_pixbufs = []
        for n in icon_names:
            pb = itd.load_icon(n,48,Gtk.IconLookupFlags.NO_SVG )
            status_pb = itd.load_icon(n,16,Gtk.IconLookupFlags.NO_SVG)
            self.icon_pixbufs.append(pb)
            self.icon_pixbufs.append(status_pb)
            self.status_icon_pixbufs.append(status_pb)

        self.status_icon = Gtk.StatusIcon()
        self.status_icon.set_visible(True)


        self.set_title_tick()
        self.set_window_icon_tick()
        self.set_status_icon_tick()

    def set_title_tick(self):
        self.set_title_to_now_datetime()
        GObject.timeout_add(self.set_title_tick_period, self.set_title_tick)
        return False

    def set_window_icon_tick(self):
        random_index = random.randrange(0,len(self.icon_pixbufs))
        pb = self.icon_pixbufs[random_index]
        self.set_icon(pb)
        GObject.timeout_add(self.set_window_icon_tick_period, self.set_window_icon_tick)
        return False

    def set_title_to_now_datetime(self):
        now_t = datetime.now()
        title = now_t.strftime("%Y-%m-%d %H:%M:%S") + \
        str(random.randrange(1,1000000))
        self.set_title(title)

    def set_status_icon_tick(self):
        random_index = random.randrange(0,len(self.status_icon_pixbufs))
        pb = self.status_icon_pixbufs[random_index]
        self.status_icon.set_from_pixbuf(pb)
        GObject.timeout_add(self.set_status_icon_tick_period, self.set_status_icon_tick)
        return False

if __name__ == '__main__':
    w = MainWindow()
    w.show_all()

    Gtk.main()
