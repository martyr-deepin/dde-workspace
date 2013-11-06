class FixedItem extends AppItem
    is_fixed_pos: true
    __show: false

    constructor: (@id, @icon, title)->
        super
        @element.draggable=false

        @open_indicator = create_img("OpenIndicator", "img/s_app_open.png", @element)
        @open_indicator.style.left = INDICATER_IMG_MARGIN_LEFT
        @open_indicator.style.display = "none"
        @set_tooltip(title)

    show: (v)->
        @__show = v
        if @__show
            @open_indicator.style.display = "block"
        else
            @open_indicator.style.display = "none"

    do_mouseover: (e) ->
        Preview_close_now()
        DCore.Dock.require_all_region()
        clearTimeout(hide_id)

    do_mouseout: (e)->
        if Preview_container.is_showing
            __clear_timeout()
            clearTimeout(tooltip_hide_id)
            DCore.Dock.require_all_region()
            launcher_mouseout_id = setTimeout(->
                update_dock_region()
            , 1000)
        else
            update_dock_region()
            setTimeout(->
                DCore.Dock.update_hide_mode()
            , 500)

class ShowDesktop extends FixedItem
    @set_time_id: null
    do_click: (e)->
        DCore.Dock.show_desktop(!@__show)
    do_buildmenu: ->
        []
    do_dragenter: (e) ->
        e.stopPropagation()
        ShowDesktop.set_time_id = setTimeout(=>
            DCore.Dock.show_desktop(true)
        , 1000)
    do_dragleave: (e) ->
        e.stopPropagation()
        clearTimeout(ShowDesktop.set_time_id)
        ShowDesktop.set_time_id = null

class LauncherItem extends FixedItem
    do_click: (e)->
        DCore.Dock.toggle_launcher(!@__show)
    do_buildmenu: ->
        []

try
    icon_launcher = DCore.get_theme_icon("start-here", 48)
    icon_desktop = DCore.get_theme_icon("show_desktop", 48)

show_launcher = new LauncherItem("show_launcher", icon_launcher, _("Launcher"))
app_list.append_app_item(show_launcher, false)

show_desktop = new ShowDesktop("show_desktop", icon_desktop, _("Show/Hide Desktop"))
app_list.append_app_item(show_desktop, false)

DCore.signal_connect("launcher_running", ->
    show_launcher.show(true)
)
DCore.signal_connect("launcher_destroy", ->
    show_launcher.show(false)
)

DCore.signal_connect("desktop_status_changed", ->
    show_desktop.show(DCore.Dock.get_desktop_status())
)
