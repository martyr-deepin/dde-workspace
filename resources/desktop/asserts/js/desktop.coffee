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
    i = new DesktopEntry item.name, item.icon, item.exec
    return i.render()


$ ->
    render_item item for item in Desktop.Core.get_desktop_items()

    $(".applet").draggable()

    $("#dialog").dialog
        autoOpen: false
        show: "blind"
        hide: "explode"

    $("#opener").click ->
        Desktop.Core.make_popup("dialog")
        $("#dialog").dialog "open"
        return false

    #$("body").contextMenu({
        #menu: "globalmenu"
    #})
    $(".item").contextMenu({
        menu: "itemmenu"
    })

    grid = document.querySelector("#grid")
    grid.width = document.body.scrollWidth
    grid.height = document.body.scrollHeight


    #ctx = grid.getContext('2d')
    #draw_grid(ctx)

