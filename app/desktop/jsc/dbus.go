package main

import . "./make_dbus"

func main() {
	DBusInstall(
		"setup_desktop_dbus_service",
		SessionDBUS("com.deepin.dde.desktop"),
		Method("FocusChanged", Callback("desktop_focus_changed"), Arg("value:gboolean")),
		Signal("ItemUpdate"),
		Signal("RichdirCreate"),
		Method("AskDeleteConfirmation", Callback("desktop_confirm_trash"), Ret("trash:gboolean"), Arg("primaryText:gchar*"), Arg("secondaryText:gchar*"), Arg("detialText:gchar*")),
	)
	OUTPUT_END()
}
