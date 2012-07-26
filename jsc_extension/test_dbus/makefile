all: web
	./a.out

py:
	./py_gen.py	proto > new.py
	chmod a+x new.py
js:
	./js_gen.py proto

web: web.c ../../lib/webview.c  ../init.c ../dbus.c ../gen/*.c ../../lib/utils.c ../dbus_*.c ../dcore.c ../forward_window.c ../desktop_entry.c
	gcc $^	`pkg-config --libs --cflags webkitgtk-3.0 dbus-glib-1` -I../ -I../../ -std=c99 -g -lX11
