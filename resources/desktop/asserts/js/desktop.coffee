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

#back_info[info.path] = info for info in Desktop.Core.get_desktop_items()


$ ->
    load_desktop_entries()

    #$(".applet").draggable()
