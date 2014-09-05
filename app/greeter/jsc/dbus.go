package main

import . "./make_dbus"

func main() {
	DBusCall(
		SystemDBUS("com.deepin.dde.lock"),
		FLAGS_NONE,

		Method("dbus_add_nopwdlogin",
			Callback("AddNoPwdLogin"),
			Ret("ret:gboolean"),
			Arg("username:char*")),

		Method("dbus_remove_nopwdlogin",
			Callback("RemoveNoPwdLogin"),
			Ret("ret:gboolean"),
			Arg("username:char*")),
	)

	DBusInstall(
		"setup_screenlock_dbus_service",
		SessionDBUS("com.deepin.dde.screenlock.Frontend"),
		Method("Hello", Callback("lock_hello")),
		Signal("Ready"),
	)

	OUTPUT_END()
}
