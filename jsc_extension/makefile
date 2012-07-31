all:
	gcc `pkg-config --cflags --libs dbus-1 gtk+-3.0 webkitgtk-3.0 dbus-glib-1` dbus_object_info.c dbus_js_convert.c  dbus_introspect.c -std=c99  -g -I../lib/

clear:
	rm -rf *.o
