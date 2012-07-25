all: js py web
	./a.out &
	./new.py

py:
	./py_gen.py	proto > new.py
	chmod a+x new.py
js:
	./js_gen.py proto > test.js

web: web.c ../../lib/webview.c  init.c ../dbus.c ../gen/gen_dbus.c ../gen/gen_desktop.c ../../lib/utils.c ../dbus_*.c
	gcc $^	`pkg-config --libs --cflags webkitgtk-3.0 dbus-glib-1` -I../ -I../../ -std=c99 -g
