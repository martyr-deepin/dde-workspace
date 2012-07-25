#--------------------------------------------------------------------------
db_conn = openDatabase("test1", "", "test widget info database", 10*1024)
db_conn.changeVersion(
    "",
    "1"
    (tx) ->
        tx.executeSql(i) for i in Recordable.db_tabls
        console.log "OK"
)
#--------------------------------------------------------------------------


render_item = (item) ->
    i = new Item item.name, item.icon, item.exec
    return i.render()


$ ->
    render_item item for item in Desktop.Core.get_desktop_items()

    $("#dialog").dialog
        autoOpen: false
        show: "blind"
        hide: "explode"

    $("#opener").click ->
        Desktop.Core.make_popup("dialog")
        $("#dialog").dialog "open"
        return false

$ ->
    s = Desktop.DBus.session_bus()
    window.shell = Desktop.DBus.get_object(s, "org.gnome.Shell", 
        "/org/gnome/Shell", "org.gnome.Shell")
    #echo shell.ListExtensions()

    window.notify = Desktop.DBus.get_object(s, "org.gnome.Magnifier",
        "/org/freedesktop/Notifications",
        "org.freedesktop.Notifications")
    echo notify.CloseNotification(0)

    #intro = Desktop.DBus.get_object(s,
        #"org.gnome.Shell", "/org/gnome/Shell",
        #"org.freedesktop.DBus.Introspectable")
    #intro.Introspect()

    echo shell.Screenshot(true, true, 1, "/dev/shm/a.png")


