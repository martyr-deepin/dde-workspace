all: web
	./a.out

py:
	./py_gen.py	proto > new.py
	chmod a+x new.py
js:
	./js_gen.py proto

web: web.c ../../lib/webview.c  ../init.c ../dbus.c ../gen/*.c ../../lib/utils.c ../dbus_*.c ../dcore.c ../forward_window.c ../desktop_entry.c
	gcc $^	`pkg-config --libs --cflags webkitgtk-3.0 dbus-glib-1` -I../ -I../../ -std=c99 -g -lX11  -D__DBUSBASIC_VALUE__=1
	valgrind --tool=memcheck --leak-check=yes --leak-check=full --show-reachable=yes ./a.out

obj_info: ../dbus_object_info.c dbus_object_test.c 
	gcc $^	`pkg-config --libs --cflags webkitgtk-3.0 dbus-glib-1` -I../ -I../../ -std=c99 -g -lX11 -D__DBUSBASIC_VALUE__=1
	valgrind --tool=memcheck --leak-check=yes --leak-check=full --show-reachable=yes ./a.out

intros: ../dbus_object_info.c ../dbus_introspect.c ../dbus_js_convert.c  dbus_introspect_test.c
	gcc $^	`pkg-config --libs --cflags webkitgtk-3.0 dbus-glib-1` -I../ -I../../ -std=c99 -g -lX11 -D__DBUSBASIC_VALUE__=1
	#valgrind --tool=memcheck --leak-check=yes --leak-check=full --show-reachable=yes ./a.out
