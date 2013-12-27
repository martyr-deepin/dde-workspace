class Applet extends AppItem
    is_fixed_pos: false
    constructor: (@id, @icon, title)->
        super
        @type = ITEM_TYPE_APPLET

        @open_indicator = create_img("OpenIndicator", SHORT_INDICATOR, @element)
        @open_indicator.style.left = INDICATER_IMG_MARGIN_LEFT
        @open_indicator.style.display = "none"
        @set_tooltip(title)

    do_mouseover: (e) =>
        super
        Preview_close_now()
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
    constructor: ->
        super
        @element.draggable=false

    show: (v)->
        @__show = v
        if @__show
            @open_indicator.style.display = "block"
        else
            @open_indicator.style.display = "none"


class ShowDesktop
    constructor:->
        DCore.signal_connect("desktop_status_changed", =>
            @set_status(DCore.Dock.get_desktop_status())
        )

    set_status: (status)->
        @__show = status

    toggle: ()=>
        DCore.Dock.show_desktop(!@__show)


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


class Trash extends FixedItem
    constructor: ->
        super
        @entry = DCore.DEntry.get_trash_entry()
        DCore.signal_connect("trash_count_changed", (info)=>
            @update(info.value)
        )

    do_rightclick: (e)=>
        e.preventDefault()
        menu = new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem(1, _("_Clean up")).setActive(DCore.DEntry.get_trash_count() != 0)
        )
        if @is_opened
            menu.append(new MenuItem(2, _("_Close")))
        xy = get_page_xy(@element)
        menu.addListener(@on_itemselected).showMenu(
            xy.x + (@element.clientWidth / 2),
            xy.y + OFFSET_DOWN,
            DEEPIN_MENU_CORNER_DIRECTION.DOWN
        )

    on_itemselected: (id)=>
        super
        calc_app_item_size()
        id = parseInt(id)
        switch id
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



class ClockBase extends FixedItem
    do_mouseover: =>
        super
        @img.style.webkitTransform = ''
        @img.style.webkitTransition = ''
        @element.style.webkitTransform = 'scale(1.1)'
        @element.style.webkitTransition = 'all 0.2s ease-out'
        @set_tooltip((new Date()).toLocaleDateString())

    do_mouseout: (e)=>
        super
        @element.style.webkitTransform = ''
        @element.style.webkitTransition = 'opacity 1s ease-in'

    start_time_settings: ->
        echo 'time settings'

    destroy: ->
        super
        clearInterval(@update_id)


class DigitClock extends ClockBase
    constructor: ->
        super
        @weekday = create_element('div', 'DigitClockWeek', @element)
        @time = create_element('div', 'DigitClockTime', @element)
        @update_time()
        @update_id = setInterval(@update_time, 1000)
        @type = DIGIT_CLOCK['type']
        DCore.Dock.set_clock_type(@type)

    update_time: =>
        @time.textContent = "#{@hour()}:#{@min()}"
        @weekday.textContent = WEEKDAY[new Date().getDay()]

    force2bit: (n)->
        if n < 10 then "0#{n}" else "#{n}"

    hour: (max_hour=24, twobit=false)->
        hour = new Date().getHours()
        switch max_hour
            when 12
                if twobit then @force2bit(hour % 12) else hour % 12
            when 24
                if twobit then @force2bit(hour) else hour

    min: (twobit=true) ->
        min = new Date().getMinutes()
        if twobit then @force2bit(min) else "#{min}"

    do_rightclick: (e)=>
        e.preventDefault()
        xy = get_page_xy(@element)
        new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem(1, _("_View as analog")),
            new MenuItem(2, _("_Time as settings"))
        ).addListener(@on_itemselected).showMenu(
            xy.x + @element.clientWidth / 2,
            xy.y + OFFSET_DOWN,
            DEEPIN_MENU_CORNER_DIRECTION.DOWN
        )

    on_itemselected: (e)=>
        id = parseInt(e)
        switch id
            when 1
                @switch_to_analog()
            when 2
                @start_time_settings()

    do_click: (e) =>
        if e.altKey
            @switch_to_analog()

    switch_to_analog: ->
        analog_clock = new AnalogClock(ANALOG_CLOCK['id'], ANALOG_CLOCK['bg'], '')
        @destroy()
        swap_element(@element, analog_clock.element)


class AnalogClock extends ClockBase
    @DEG_PER_HOUR: 3
    @DEG_PER_MIN: 6
    constructor: ->
        super
        @short_pointer = create_img('pointer', 'img/short-pointer.svg', @element)
        @long_pointer = create_img('pointer', 'img/long-pointer.svg', @element)
        @update_time()
        @update_id = setInterval(@update_time, 1000)
        @type = ANALOG_CLOCK['type']
        DCore.Dock.set_clock_type(@type)

    update_time: =>
        date = new Date()
        @short_pointer.style.webkitTransform = "rotate(#{date.getHours() * AnalogClock.DEG_PER_HOUR + date.getMinutes()}deg)"
        @long_pointer.style.webkitTransform = "rotate(#{date.getMinutes() * AnalogClock.DEG_PER_MIN}deg)"

    do_rightclick: =>
        xy = get_page_xy(@element)
        new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem(1, _("_View as digit")),
            new MenuItem(2, _("_Time settings"))
        ).addListener(@on_itemselected).showMenu(
            xy.x + @element.clientWidth / 2,
            xy.y + OFFSET_DOWN,
            DEEPIN_MENU_CORNER_DIRECTION.DOWN
        )

    on_itemselected: (e)=>
        id = parseInt(e)
        switch id
            when 1
                @switch_to_digit()
            when 2
                @start_time_settings()

    do_click: (e) =>
        if e.altKey
            @switch_to_digit()

    switch_to_digit: ->
        digit_clock = new DigitClock(DIGIT_CLOCK['id'], DIGIT_CLOCK['bg'], '')
        @destroy()
        swap_element(@element, digit_clock.element)


create_clock = (type)->
    if type == DIGIT_CLOCK['type']
        new DigitClock(DIGIT_CLOCK['id'], DIGIT_CLOCK['bg'], '')
    else
        new AnalogClock(ANALOG_CLOCK['id'], ANALOG_CLOCK['bg'], '')


try
    icon_launcher = DCore.get_theme_icon("start-here", 48)

show_launcher = new LauncherItem("show_launcher", icon_launcher, _("Launcher"))
show_desktop = new ShowDesktop()
trash = new Trash("trash", Trash.get_icon(DCore.DEntry.get_trash_count()), _("Trash"))
clock = create_clock(DCore.Dock.clock_type())
