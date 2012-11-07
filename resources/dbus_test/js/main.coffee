class DBusItem extends Widget
    container = $("#list")
    constructor: (@name, @obj) ->
        super
        @element.innerHTML="
            <div class=name>#{name}</div>
        "
        container.appendChild(@element)

        @funcs = {}
        for k,v of @obj
            @funcs[k] = v

    do_click: (e) ->
        @show_info(@funcs)

    show_info : (funcs)->
        infos.innerHTML=""
        for k, v of funcs
            id = @name + k
            new Item(id, k, v)

list = DCore.DBus.session("org.freedesktop.DBus").ListNames_sync()
dbus_list = []
for i in list when i.charAt(0) != ':'
    info =
        name: i
        obj: DCore.DBus.session(i)

    new DBusItem(i, DCore.DBus.session(i))




class Item extends Widget
    infos = $("#infos")
    constructor: (@id, @name, @func) ->
        super
        @element.innerHTML="
        #{@name}
        "

        infos.appendChild(@element)

    do_click: (e) ->
        echo Widget.look_up(@id)
