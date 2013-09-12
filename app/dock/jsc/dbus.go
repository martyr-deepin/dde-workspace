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
        Method("CloseApp", Callback("dock_bus_close_window"), Arg("appid:gchar*")),
        Method("ActiveApp", Callback("dock_bus_active_window"), Arg("appid:gchar*")),
        Method("ListApps", Callback("dock_bus_list_apps"), Ret("clients:gchar*")),
    )
    DBusCall(
        SessionDBUS("com.deepin.dde.desktop"),
        FLAGS_NONE,
        Method("dbus_set_desktop_focused", Callback("FocusChanged"),  Arg("state:gboolean")),
    )
    DBusCall(
        SessionDBUS("com.deepin.dde.launcher"),
        FLAGS_NONE,
        Method("dbus_launcher_hide", Callback("Hide")),
    )
    OUTPUT_END()
}
