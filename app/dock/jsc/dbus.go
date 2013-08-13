package main
import . "make_dbus"

func main() {
    DBusInstall(
        "setup_dock_dbus_service",
        SessionDBUS("com.deepin.dde.dock"),
        Method("RequestDock", Callback("dock_request_dock"), Arg("path:gchar*")),
        Method("ShowDesktop", Callback("dock_show_desktop"), Arg("value:gboolean")),
        Method("ToggleShow", Callback("dock_toggle_show")),
        Method("ShowInspector", Callback("dock_show_inspector")),
    )
    DBusCall(
        SessionDBUS("com.deepin.dde.desktop"),
        FLAGS_NONE,
        Method("dbus_set_desktop_focused", Callback("FocusChanged"),  Arg("state:gboolean")), 
    )
    OUTPUT_END()
}
