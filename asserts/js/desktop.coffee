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
    render_item item for item in DCore.get_desktop_items()

    $("#dialog").dialog
        autoOpen: false
        show: "blind"
        hide: "explode"

    $("#opener").click ->
        $("#dialog").dialog "open"
        DCore.make_popup("dialog")
        return false
