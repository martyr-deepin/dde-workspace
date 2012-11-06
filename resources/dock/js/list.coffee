container = document.getElementById('icon_list')

class Client extends Widget
    constructor: (@id, @icon, @title)->
        super
        @update_content @title, @icon

        container.appendChild(@element)

        @element.addEventListener('click', @click)
        @element.addEventListener('dblclick', @dbclick)

        @element.addEventListener('mouseover', @over)
    active: ->
        @element.style.background = "rgba(0, 100, 100, 1)"
    deactive: ->
        @element.style.background = "rgba(0, 0, 0, 0)"
    withdraw: ->
        @element.style.display = "None"
    normal: ->
        @element.style.display = "block"
    click: (e) ->
        DCore.Dock.set_active_window(@id)
    dbclick: (e) ->
        DCore.Dock.minimize_window(@id)
    over: (e) =>
        offset = @element.offsetLeft - 150
        if offset < 0
            offset = 0
        preview_active(@id, offset)
    update_content: (title, icon) ->
        @element.innerHTML = "
        <img src=#{icon} title=\"#{title}\"/>
        "


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
    echo "task_added...."
    w = Widget.look_up(info.id)
    if w
        w.update_content(info.title, info.icon)
    else
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
