package main
import . "make_dbus"


func main() {
    DBusInstall(
        "setup_greeter_dbus_service",
        SystemDBUS("com.deepin.dde.greeter"),
        Method("StartAnimation", Callback("dbus_handle_start_animation")),
        Method("StopAnimation", Callback("dbus_handle_stop_animation")),
        Method("StartLogin", Callback("dbus_handle_start_login")),
    )

    // DBusCall(
    //     SystemDBUS("com.deepin.dde.lock"),
    //     FLAGS_NONE,
    //     Method("dbus_add_to_nopwd_login_group",
    //         Callback("AddToNoPasswordLoginGroup"), Arg("username:char*")),
    //     Method("dbus_remove_from_nopwd_login_group",
    //         Callback("RemoveNoPasswordLoginGroup"), Arg("username:char*")),
    // )

    // DBusCall(
    //     SessionDBUS("com.deepin.dde.greeter"),
    //     FLAGS_NONE,
    //     Method("dbus_start_animation", Callback("StartAnimation")),
    //     Method("dbus_stop_animation", Callback("StopAnimation")),
    //     Method("dbus_start_login", Callback("StartLogin")),
    // )
    OUTPUT_END()
}
