container = document.getElementById('icon_list')
preview = document.getElementById('preview')

#for info in DCore.Dock.get_tasklist()


class Client extends Widget
    constructor: (@id, @icon, @title)->
        super
        @element.innerHTML = "
        <img src=#{@icon} title=#{@title}/>
        "
        @element.addEventListener('click', @click)
        @element.addEventListener('dblclick', @dbclick)
        @element.addEventListener('mouseover', @over)
        container.appendChild(@element)
    over: ->
        setInterval( =>
            data_uri = DCore.Dock.fetch_window_preview(@id, 300, 200)
            preview.src = data_uri
        200)

    active: ->
        el = @element.children[0]
        el.style.width = "48px"
        el.style.height = "48px"
    deactive: ->
        el = @element.children[0]
        el.style.width = "32px"
        el.style.height = "32px"
    withdraw: ->
        @element.style.display = "None"
    normal: ->
        @element.style.display = "block"
    click: (e) ->
        DCore.Dock.set_active_window(@id)
    dbclick: (e) ->
        DCore.Dock.minimize_window(@id)



active_win = null
change_active_window = (c) ->
    if active_win?
        active_win.deactive()
    active_win = c
    active_win.active()


DCore.signal_connect("active_window_changed", (info)->
    client = Widget.look_up(info.id)
    change_active_window(client)
)

DCore.signal_connect("task_added", (info) ->
    new Client(info.id, info.icon, info.title)
)

DCore.signal_connect("task_removed", (info) ->
    Widget.look_up(info.id).destroy()
)

DCore.signal_connect("task_withdraw", (info) ->
    Widget.look_up(info.id).withdraw()
)

DCore.signal_connect("task_normal", (info) ->
    Widget.look_up(info.id).normal()
)

DCore.Dock.emit_update_task_list()
