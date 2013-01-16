class FixedItem extends AppItem
    constructor: (@id, @icon)->
        super
        @element.draggable=false
    is_fixed_pos: true


class ShowDesktop extends FixedItem
    do_click: (e)->
        @show = false if not @show
        @show = !@show
        DCore.Dock.show_desktop(@show)
    do_buildmenu: ->
        []

class LauncherItem extends FixedItem
    do_click: (e)->
        @show = !@show
        DCore.run_command("launcher")
    do_buildmenu: ->
        []

try
    icon_launcher = DCore.get_theme_icon("start-here", 48)
    icon_desktop = DCore.get_theme_icon("show_desktop", 48)

show_launcher = new LauncherItem("show_launcher", icon_launcher)
app_list.append(show_launcher)
show_desktop = new ShowDesktop("show_desktop", icon_desktop)
app_list.append(show_desktop)
