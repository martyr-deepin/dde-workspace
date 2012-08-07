#--------------------------------------------------------------------------
#db_conn = openDatabase("test1", "", "test widget info database", 10*1024)
#db_conn.changeVersion(
    #"",
    #"1"
    #(tx) ->
        #tx.executeSql(i) for i in Recordable.db_tabls
        #console.log "OK"
#)
#--------------------------------------------------------------------------


$ ->
    create_item(info).render() for info in Desktop.Core.get_desktop_items()

    #$(".applet").draggable()

    grid = document.querySelector("#grid")
    grid.width = document.body.scrollWidth
    grid.height = document.body.scrollHeight


    ctx = grid.getContext('2d')
    draw_grid(ctx)

