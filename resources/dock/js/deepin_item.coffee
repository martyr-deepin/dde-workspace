class Applet extends Item
    is_fixed_pos: false
    constructor: (@id, @icon, title, @container)->
        super
        @type = ITEM_TYPE_APPLET

        @indicatorWarp = create_element(tag:'div', class:"indicatorWarp", @element)
        @openIndicator = create_img(src:OPEN_INDICATOR, class:"indicator OpenIndicator", @indicatorWarp)
        @openIndicator.style.display = "none"
        # @open_indicator = create_img("OpenIndicator", OPEN_INDICATOR, @element)
        # @open_indicator.style.left = INDICATER_IMG_MARGIN_LEFT
        # @open_indicator.style.display = "none"

    on_mouseover: (e) =>
        super
        Preview_close_now()
        clearTimeout(hide_id)

    on_mouseout: (e)=>
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
    constructor:(@id, @icon, title, @container)->
        super
        @element.draggable = false

    show: (v)->
        @__show = v
        if @__show
            @openIndicator.style.display = "block"
        else
            @openIndicator.style.display = "none"

    set_status: (status)=>
        @show(status)


class PrefixedItem extends FixedItem
    constructor:(@id, @icon, title)->
        super(@id, @icon, title, $("#pre_fixed"))
        # $("#pre_fixed").appendChild(@element)


class SystemItem extends AppItem#ClientGroup
    is_fixed_pos: true
    constructor:(@id, @icon, title)->
        super(@id, @icon, title, $("#system"))
        @element.draggable = false
        $("#system").appendChild(@element)


class PostfixedItem extends FixedItem
    constructor:(@id, @icon, title)->
        super(@id, @icon, title, $("#post_fixed"))


class LauncherItem extends PrefixedItem
    constructor: (@id, @icon, @title)->
        super
        @set_tooltip(@title)
        DCore.signal_connect("launcher_running", =>
            @show(true)
        )
        DCore.signal_connect("launcher_destroy", =>
            @show(false)
        )

    on_click: (e)=>
        super
        DCore.Dock.toggle_launcher(!@__show)


class Trash extends PostfixedItem
    constructor:(@id, @icon, title)->
        super
        @set_tooltip(title)
        @entry = DCore.DEntry.get_trash_entry()
        DCore.signal_connect("trash_count_changed", (info)=>
            @update(info.value)
        )

    on_rightclick: (e)=>
        super
        e.preventDefault()
        e.stopPropagation()
        menu = new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem(1, _("_Clean up")).setActive(DCore.DEntry.get_trash_count() != 0)
        )
        if @is_opened
            menu.append(new MenuItem(2, _("_Close")))
        xy = get_page_xy(@element)
        # echo menu
        menu.addListener(@on_itemselected).showMenu(
            xy.x + (@element.clientWidth / 2),
            xy.y + OFFSET_DOWN,
            DEEPIN_MENU_CORNER_DIRECTION.DOWN
        )

    on_itemselected: (id)=>
        # super
        calc_app_item_size()
        id = parseInt(id)
        console.log(id)
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

    on_click: (e)=>
        super
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


class Time extends SystemItem
    constructor:->
        super
        @time = create_element('div', 'DigitClockTime', @img)
        @update_time()
        @update_id = setInterval(@update_time, 1000)
        @type = DIGIT_CLOCK['type']
        @indicatorWarp.style.display = 'none'

    isNormal:->
        true

    on_mouseover:=>
        super
        @set_tooltip((new Date()).toLocaleDateString())

    on_mouseout:=>
        super

    update_time: =>
        @time.textContent = "#{@hour()}:#{@min()}"

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


class ClockBase extends SystemItem
    constructor:->
        super

    on_mouseover: =>
        super
        @img.style.webkitTransform = ''
        @img.style.webkitTransition = ''
        # @element.style.webkitTransform = 'scale(1.1)'
        @element.style.webkitTransform = 'translateY(-5px)'
        @element.style.webkitTransition = 'all 100ms'
        @set_tooltip((new Date()).toLocaleDateString())

    on_mouseout: (e)=>
        super
        @element.style.webkitTransform = ''
        # @element.style.webkitTransition = 'opacity 1s ease-in'
        @element.style.webkitTransition = 'all 0.2s'

    on_click: (e)=>
        super

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

    on_rightclick: (e)=>
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

    on_click: (e) =>
        super
        if e.altKey
            @switch_to_analog()

    switch_to_analog: ->
        analog_clock = new AnalogClock(ANALOG_CLOCK['id'], ANALOG_CLOCK['bg'], '')
        swap_element(analog_clock.element, @element)
        @destroy()


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

    on_rightclick: =>
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

    on_click: (e) =>
        super
        if e.altKey
            @switch_to_digit()

    switch_to_digit: ->
        digit_clock = new DigitClock(DIGIT_CLOCK['id'], DIGIT_CLOCK['bg'], '')
        swap_element(@element, digit_clock.element)
        @destroy()


create_clock = (type)->
    if type == DIGIT_CLOCK['type']
        new DigitClock(DIGIT_CLOCK['id'], DIGIT_CLOCK['bg'], '')
    else
        new AnalogClock(ANALOG_CLOCK['id'], ANALOG_CLOCK['bg'], '')
