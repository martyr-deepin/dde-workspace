class Applet extends AppItem
    is_fixed_pos: false

    constructor: (@id, @icon, title)->
        super
        @type = ITEM_TYPE_PLUGIN
        @element.draggable=false

        @open_indicator = create_img("OpenIndicator", SHORT_INDICATOR, @element)
        @open_indicator.style.left = INDICATER_IMG_MARGIN_LEFT
        @open_indicator.style.display = "none"
        @set_tooltip(title)

    do_mouseover: (e) =>
        super
        Preview_close_now()
        DCore.Dock.require_all_region()
        clearTimeout(hide_id)

    do_mouseout: (e)=>
        super
        if Preview_container.is_showing
            __clear_timeout()
            clearTimeout(tooltip_hide_id)
            DCore.Dock.require_all_region()
            launcher_mouseout_id = setTimeout(->
                calc_app_item_size()
                # update_dock_region()
            , 1000)
        else
            calc_app_item_size()
            # update_dock_region()
            setTimeout(->
                DCore.Dock.update_hide_mode()
            , 500)


class FixedItem extends Applet
    is_fixed_pos: true
    __show: false

    show: (v)->
        @__show = v
        if @__show
            @open_indicator.style.display = "block"
        else
            @open_indicator.style.display = "none"


class ShowDesktop extends FixedItem
    @set_time_id: null
    constructor:->
        super
        DCore.signal_connect("desktop_status_changed", =>
            @show(DCore.Dock.get_desktop_status())
        )
    do_click: (e)=>
        DCore.Dock.show_desktop(!@__show)
    do_buildmenu: =>
        []
    do_dragenter: (e) =>
        e.stopPropagation()
        ShowDesktop.set_time_id = setTimeout(=>
            DCore.Dock.show_desktop(true)
        , 1000)
    do_dragleave: (e) =>
        e.stopPropagation()
        clearTimeout(ShowDesktop.set_time_id)
        ShowDesktop.set_time_id = null


class LauncherItem extends FixedItem
    constructor: ->
        super
        DCore.signal_connect("launcher_running", =>
            @show(true)
        )
        DCore.signal_connect("launcher_destroy", =>
            @show(false)
        )
    do_click: (e)=>
        DCore.Dock.toggle_launcher(!@__show)
    do_buildmenu: =>
        []


class Trash extends FixedItem
    constructor: ->
        super
        @entry = DCore.DEntry.get_trash_entry()
        DCore.signal_connect("trash_count_changed", (info)=>
            @update(info.value)
        )

    do_buildmenu:=>
        menu = [[1, _("_Clean up"), DCore.DEntry.get_trash_count() != 0]]
        if @is_opened
            menu.push([2, _("_Close")])
        menu

    do_itemselected: (e)=>
        super
        calc_app_item_size()
        switch e.id
            when 1
                loop
                    try
                        DCore.DBus.session_object("org.gnome.Nautilus",
                                                  "/org/gnome/Nautilus",
                                                  "org.gnome.Nautilus.FileOperations").EmptyTrash()
                        break
                @update()
            when 2
                DCore.Dock.close_window(@id)

    do_click: =>
        if !DCore.DEntry.launch(@entry, [])
            confirm(_("Can not open this file."), _("Warning"))

    do_drop: (evt)=>
        evt.stopPropagation()
        evt.preventDefault()
        if dnd_is_file(evt) or dnd_is_desktop(evt)
            tmp_list = []
            for file in evt.dataTransfer.files
                e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                if not e? then continue
                tmp_list.push(e)
            if tmp_list.length > 0 then DCore.DEntry.trash(tmp_list)

    do_dragenter : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        evt.dataTransfer.dropEffect = "move"

    do_dragover : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        evt.dataTransfer.dropEffect = "move"

    do_dragleave : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        evt.dataTransfer.dropEffect = "move"

    show_indicator: ->
        @is_opened = true
        @open_indicator.style.display = "block"

    hide_indicator:->
        @is_opened = false
        @id = 0
        @open_indicator.style.display = "none"

    set_id: (id)->
        @id = id
        @

    @get_icon: (n) ->
        if n == 0
            DCore.get_theme_icon(EMPTY_TRASH_ICON, 48)
        else
            DCore.get_theme_icon(FULL_TRASH_ICON, 48)

    update: (n=null)->
        n = DCore.DEntry.get_trash_count() if n == null
        @img.src = Trash.get_icon(n)


class DigitClock extends Applet
    constructor: ->
        super
        @date = new Date()
        @weekday = create_element('div', 'DigitClockWeek', @element)
        @time = create_element('div', 'DigitClockTime', @element)
        @update_time()
        setInterval(@update_time, 1000)

    update_time: =>
        @time.textContent = "#{@hour()}:#{@min()}"
        @weekday.textContent = WEEKDAY[@date.getDay()]

    force2bit: (n)->
        if n < 10 then "0#{n}" else "#{n}"

    hour: (max_hour=24, twobit=false)->
        hour = @date.getHours()
        switch max_hour
            when 12
                if twobit then @force2bit(hour % 12) else hour % 12
            when 24
                if twobit then @force2bit(hour) else hour

    min: (twobit=true) ->
        min = @date.getMinutes()
        if twobit then @force2bit(min) else "#{min}"

    do_mouseover: =>
        super
        @set_tooltip((new Date()).toLocaleDateString())


class AnalogClock extends Applet
    @DEG_PER_HOUR: 3
    @DEG_PER_MIN: 6
    constructor: ->
        super
        @date = new Date()
        @short_pointer = create_img('pointer', 'img/short-pointer.svg', @element)
        @long_pointer = create_img('pointer', 'img/long-pointer.svg', @element)
        @update_time()
        @update_id = setInterval(@update_time, 1000)

    update_time: =>
        @short_pointer.style.webkitTransform = "rotate(#{@date.getHours() * AnalogClock.DEG_PER_HOUR + @date.getMinutes()}deg)"
        @long_pointer.style.webkitTransform = "rotate(#{@date.getMinutes() * AnalogClock.DEG_PER_MIN}deg)"

    do_mouseover: =>
        super
        # @set_tooltip((new Date()).toLocaleDateString())


try
    icon_launcher = DCore.get_theme_icon("start-here", 48)
    icon_desktop = DCore.get_theme_icon("show_desktop", 48)

show_launcher = new LauncherItem("show_launcher", icon_launcher, _("Launcher"))
show_desktop = new ShowDesktop("show_desktop", icon_desktop, _("Show/Hide Desktop"))
trash = new Trash("trash", Trash.get_icon(DCore.DEntry.get_trash_count()), _("Trash"))
