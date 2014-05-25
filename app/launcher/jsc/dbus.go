package main

import . "./make_dbus"

func main() {
	DBusInstall(
		"setup_launcher_dbus_service",
		SessionDBUS("com.deepin.dde.launcher"),
		Method("Show", Callback("launcher_show")),
		Method("Hide", Callback("launcher_hide")),
		Method("Toggle", Callback("launcher_toggle")),
		Method("Exit", Callback("launcher_quit")),
		Signal("Shown"),
		Signal("Closed"),
	)
	DBusCall(
		SessionDBUS("com.deepin.dde.launcher"),
		FLAGS_NONE,
		Method("dbus_launcher_show", Callback("Show")),
		Method("dbus_launcher_hide", Callback("Hide")),
		Method("dbus_launcher_toggle", Callback("Toggle")),
	)
	OUTPUT_END()
}
