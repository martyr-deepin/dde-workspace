new: taskbarnew.c lib/dcore.c lib/webview.c lib/marshal.c lib/taskbar.c lib/tray_manager.c
	gcc -o new $^ `pkg-config --libs --cflags gtk+-3.0 webkitgtk-3.0` -std=c99 -lX11 -g

tray: lib/testtray.c lib/tray_manager.c lib/marshal.c lib/taskbar.c lib/webview.c lib/dcore.c
	gcc -o tray $^ `pkg-config --libs --cflags gtk+-2.0 webkit-1.0` -lX11 -std=c99


gen_marshal: lib/marshal.list
	glib-genmarshal --header --prefix "_tray_marshal" $^  > lib/marshal.h
	glib-genmarshal --body $^  --prefix "_tray_marshal" > lib/marshal.c


all: taskbar.c
	gcc -o taskbar taskbar.c `pkg-config --libs --cflags-only-I gtk+-2.0 webkit-1.0` -lxcb
