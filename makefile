all: jsc_extension desktop

jsc_extension: jsc_extension/*.cfg jsc_extension/jsc_gen.py
	cd jsc_extension && python jsc_gen.py
	cd jsc_extension && gcc -c *.c `pkg-config --libs --cflags webkitgtk-3.0 dbus-glib-1` -std=c99 -g


desktop: desktop.c jsc_extension/*.c jsc_extension/gen/*.c lib/webview.c  lib/utils.c 
	gcc -o desktop $^  -I./jsc_extension -L~/.lib `pkg-config --libs --cflags gtk+-3.0 webkitgtk-3.0 dbus-glib-1` -std=c99 -lX11 -g 


taskbar: taskbar.c lib/dcore.c lib/webview.c lib/marshal.c lib/taskbar.c lib/tray_manager.c lib/utils.c lib/desktop_entry.c lib/LauncherInspectorWindow.c
	gcc -o taskbar $^ `pkg-config --libs --cflags gtk+-3.0 webkitgtk-3.0` -std=c99 -lX11 -g

tray: lib/testtray.c lib/tray_manager.c lib/marshal.c lib/taskbar.c lib/webview.c lib/dcore.c
	gcc -o tray $^ `pkg-config --libs --cflags gtk+-2.0 webkit-1.0` -lX11 -std=c99


gen_marshal: lib/marshal.list
	glib-genmarshal --header --prefix "_tray_marshal" $^  > lib/marshal.h
	glib-genmarshal --body $^  --prefix "_tray_marshal" > lib/marshal.c
