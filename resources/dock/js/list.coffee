container = document.getElementById('icon_list')

#for info in DCore.Dock.get_tasklist()

class Client extends Widget
    constructor: (@id, @icon, @title)->
        super
        @element.innerHTML = "
        <img src=#{@icon} title=#{@title}/>
        "
        container.appendChild(@element)



do_active_window_change = (info) ->
    echo ("active window.. #{info.ID}")

do_task_added = (info) ->
    new Client(info.id, info.icon, info.title)

DCore.signal_connect("active_window_changed", do_active_window_change)
DCore.signal_connect("task_added", do_task_added)

DCore.Dock.emit_update_task_list()



