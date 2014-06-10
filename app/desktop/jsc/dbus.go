package main

import . "./make_dbus"

func main() {
	DBusInstall(
		"setup_desktop_dbus_service",
		SessionDBUS("com.deepin.dde.desktop"),
		Method("FocusChanged", Callback("desktop_focus_changed"), Arg("value:gboolean")),
		Signal("DesktopFileCreate"),
		Signal("RichdirCreate"),
	)
    OUTPUT_END()
}
