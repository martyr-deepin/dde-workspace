package main
import . "make_dbus"

func main() {
	DBusInstall(
		"setup_apptray_dbus_service",
		SessionDBUS("com.deepin.dde.apptray"),
		Method("Show", Callback("tray_show_real_now")),
		Method("Hide", Callback("tray_hide_real_now")),
	)
	OUTPUT_END()
}
