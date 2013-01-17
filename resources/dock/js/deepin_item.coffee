class FixedItem extends AppItem
    is_fixed_pos: true
    __active: false

    constructor: (@id, @icon)->
        super
        @element.draggable=false

        @indicate = create_img("OpenIndicate", "img/s_app_open.png", @element)
        @indicate.style.left = INDICATER_IMG_MARGIN_LEFT
        @indicate.style.display = "none"

    toggle: (v)->
        if v
            @__active = v
        else
            @__active = !@__active

        if @__active
            @indicate.style.display = "block"
        else
            @indicate.style.display = "none"
        return @__active

class ShowDesktop extends FixedItem
    do_click: (e)->
        DCore.Dock.show_desktop(@toggle)
    do_buildmenu: ->
        []

class LauncherItem extends FixedItem
    do_click: (e)->
        DCore.Dock.toggle_launcher(!@__active)
    do_buildmenu: ->
        []

try
    icon_launcher = DCore.get_theme_icon("start-here", 48)
    icon_desktop = DCore.get_theme_icon("show_desktop", 48)

show_launcher = new LauncherItem("show_launcher", icon_launcher)
DCore.signal_connect("launcher_running", ->
    show_launcher.toggle(true)
)
DCore.signal_connect("launcher_destroy", ->
    show_launcher.toggle(false)
)

app_list.append(show_launcher)

show_desktop = new ShowDesktop("show_desktop", icon_desktop)
app_list.append(show_desktop)
