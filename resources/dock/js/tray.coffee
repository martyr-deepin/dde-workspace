na = document.getElementById('notifyarea')
tray_icons = {}
update_icons = ->
    for k, v of tray_icons
        v.update()

class TrayIcon extends Widget
    constructor: (@id, @clss, @name) ->
        super
        na.appendChild(@element)

    update: ->
        x = @element.offsetLeft + @element.clientLeft
        y = @element.offsetTop + @element.clientTop + 200
        DCore.Dock.set_tray_icon_position(@id, x, y)


for info in DCore.Dock.get_tray_icon_list()
    icon = new TrayIcon(info.id, info.class, info.name)
    tray_icons[info.id] = icon
    #We can't update icon position at this momenet because the div element's layout hasn't done.
update_icons()

do_tray_icon_added = (info) ->
    icon = new TrayIcon(info.id, info.class, info.name)
    tray_icons[info.id] = icon
    setTimeout(update_icons, 30)

do_tray_icon_removed = (info) ->
    icon = Widget.look_up(info.id)
    icon.destroy()
    delete tray_icons[info.id]
    setTimeout(update_icons, 30)

DCore.signal_connect('tray_icon_added', do_tray_icon_added)
DCore.signal_connect('tray_icon_removed', do_tray_icon_removed)
