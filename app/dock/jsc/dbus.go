package main

import . "./make_dbus"

func main() {
	DBusInstall(
		"setup_dock_dbus_service",
		SessionDBUS("com.deepin.dde.dock"),
		Method("ToggleShow", Callback("dock_toggle_show")),
		Method("ShowInspector", Callback("dock_show_inspector")),
		Method("MessageNotify",
			Callback("dock_bus_message_notify"),
			Arg("appid:gchar*"),
			Arg("itemid:gchar*"),
		),
		Method("Show", Callback("dock_show_now")),
		Method("Hide", Callback("dock_hide_now")),
		Method("Xid", Callback("dock_xid"), Ret("xid:guint64")),
	)
	DBusCall(
		SessionDBUS("com.deepin.dde.desktop"),
		FLAGS_NONE,
		Method("dbus_set_desktop_focused", Callback("FocusChanged"), Arg("state:gboolean")),
	)
	DBusCall(
		SessionDBUS("com.deepin.dde.launcher"),
		FLAGS_NONE,
		Method("dbus_launcher_hide", Callback("Hide")),
	)
	OUTPUT_END()
}
