container = document.getElementById('icon_list')

#for info in DCore.Dock.get_tasklist()


class Client extends Widget
    constructor: (@id, @icon, @title)->
        super
        @element.innerHTML = "
        <img src=#{@icon} title=#{@title}/>
        "
        container.appendChild(@element)
    active: ->
        @element.style.background = "rgba(100, 0, 0, 0.8)"
    deactive: ->
        echo("deactive")
        @element.style.background = "rgba(0, 0, 0, 0)"

active_win = null
change_active_window = (c) ->
    if active_win?
        active_win.deactive()
    active_win = c
    active_win.active()


do_active_window_change = (info) ->
    client = Widget.look_up(info.id)
    change_active_window(client)

do_task_added = (info) ->
    new Client(info.id, info.icon, info.title)

do_task_removed = (info) ->
    Widget.look_up(info.id).destroy()

DCore.signal_connect("active_window_changed", do_active_window_change)
DCore.signal_connect("task_added", do_task_added)
DCore.signal_connect("task_removed", do_task_removed)

DCore.Dock.emit_update_task_list()



