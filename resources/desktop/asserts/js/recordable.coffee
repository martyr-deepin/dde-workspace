Recordable =
    db_tabls : []
    __init__: (parms) -> 
        @::get_fields = parms
        @::create_table()

    table : -> "__d_#{@constructor.name}__"
    fields : -> @get_fields.join()
    fields_n : -> ('?' for i in [1..@get_fields.length])

    save: ->
        values = (this["get_#{i}"]() for i in @get_fields)
        fn = @fields_n()
        db_conn.transaction (tx) =>
            tx.executeSql(
                "replace into #{@table()} (#{@fields()}) values (#{fn});"
                values
                (result) ->
                (tx, error) -> console.log(error)
            )

    create_table: ->
        fs = @fields().split(',').slice(1).join(' Int, ') + " Int"
        Recordable.db_tabls.push "CREATE TABLE #{@table()} (id REAL UNIQUE, #{fs});"

    load: ->
        db_conn.transaction (tx) =>
            tx.executeSql(
                "select #{@fields()} from #{@table()} where id = ?",
                [@id],
                (tx, r) =>
                    p = r.rows.item(0)
                    this["set_#{field}"](p[field]) for field in @get_fields
                (tx, error) =>
            )
