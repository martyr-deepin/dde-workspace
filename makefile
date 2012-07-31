C_FLAGS = `pkg-config --libs --cflags webkitgtk-3.0 dbus-glib-1 x11` -std=c99 -g

DEEPIN_FLAGS = $(C_FLAGS) -D__DEEPIN_WEBKIT__=1 -D__DBUSBASIC_VALUE__=1

all: jsc_extension desktop

jsc_extension: jsc_extension/*.cfg jsc_extension/jsc_gen.py
	cd jsc_extension && python jsc_gen.py
	cd jsc_extension && gcc -c $(DEEPIN_FLAGS)


desktop: desktop.c jsc_extension/*.c jsc_extension/gen/*.c lib/webview.c  lib/utils.c 
	gcc -o desktop $^  -I./jsc_extension -L~/.lib $(DEEPIN_FLAGS)


taskbar: taskbar.c jsc_extension/*.c jsc_extension/gen/*.c lib/webview.c lib/marshal.c lib/taskbar.c lib/tray_manager.c lib/utils.c 
	gcc -o taskbar $^  -I./jsc_extension -L~/.lib $(DEEPIN_FLAGS)

tray: lib/testtray.c lib/tray_manager.c lib/marshal.c lib/taskbar.c lib/webview.c lib/dcore.c
	gcc -o tray $^ `pkg-config --libs --cflags gtk+-2.0 webkit-1.0` -lX11 -std=c99


gen_marshal: lib/marshal.list
	glib-genmarshal --header --prefix "_tray_marshal" $^  > lib/marshal.h
	glib-genmarshal --body $^  --prefix "_tray_marshal" > lib/marshal.c
