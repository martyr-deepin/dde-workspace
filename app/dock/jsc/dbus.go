package main

import . "./make_dbus"

func main() {
	DBusInstall(
		"setup_dock_dbus_service",
		SessionDBUS("com.deepin.dde.dock"),
		// Method("ToggleShow", Callback("dock_toggle_show")),
		Method("ShowInspector", Callback("dock_show_inspector")),
		Method("MessageNotify",
			Callback("dock_bus_message_notify"),
			Arg("appid:gchar*"),
			Arg("itemid:gchar*"),
		),
		// Method("Show", Callback("dock_show_now")),
		// Method("Hide", Callback("dock_hide_now")),
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
	DBusCall(
		SessionDBUS("com.deepin.daemon.Dock",
			"/dde/dock/HideStateManager",
			"dde.dock.HideStateManger",
		),
		FLAGS_NONE,
		Method("dbus_dock_daemon_update_hide_state",
			Callback("UpdateState"),
			// Arg("tmp:gboolean"),
		),
		Method(
			"dbus_dock_daemon_cancel_toggle_show",
			Callback("CancelToggleShow"),
		),
	)
	DBusCall(
		SessionDBUS(
			"com.deepin.daemon.Dock",
			"/dde/dock/XMouseAreaProxyer",
			"dde.dock.XMouseAreaProxyer",
		),
		FLAGS_NONE,
		Method(
			"dbus_mousearea_register_fullscreen",
			Callback("RegisterFullScreen"),
		),
	)
	OUTPUT_END()
}
