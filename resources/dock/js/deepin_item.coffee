class Applet extends Item
    is_fixed_pos: false
    constructor: (@id, icon, title, @container)->
        super
        @type = ITEM_TYPE_APPLET

        @indicatorWrap = create_element(tag:'div', class:"indicatorWrap", @element)
        @openingIndicator = create_img(src:OPENING_INDICATOR, class:"indicator OpeningIndicator", @indicatorWrap)
        @openIndicator = create_img(src:OPEN_INDICATOR, class:"indicator OpenIndicator", @indicatorWrap)
        @openIndicator.style.display = 'none'

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
            normal_mouseout_id = setTimeout(->
                calc_app_item_size()
                if debugRegion
                    console.warn("[Applet.on_mouseout] update_dock_region")
                update_dock_region()
            , 1000)
        else
            calc_app_item_size()
            if debugRegion
                console.warn("[Applet.on_mouseout] update_dock_region")
            update_dock_region()
            setTimeout(->
                # DCore.Dock.update_hide_mode()
                hideStatusManager.updateState()
            , 500)


class FixedItem extends Applet
    is_fixed_pos: true
    __show: false
    constructor:(@id, icon, title, @container)->
        super
        @img.draggable = false

    show: (v)->
        @__show = v
        if @__show
            @openIndicator.style.display = ""
        else
            @openIndicator.style.display = "none"

    set_status: (status)=>
        @show(status)

    on_dragover:(e)=>
        super
        e.dataTransfer.dropEffect = 'none'
        _isDragging = false

    on_dragenter:(e)=>
        super
        updatePanel()


class PrefixedItem extends FixedItem
    constructor:(@id, icon, title)->
        super(@id, icon, title, $("#pre_fixed"))
        @imgContainer.draggable = false
        # $("#pre_fixed").appendChild(@element)

    isFirstElementChild:->
        @container.firstElementChild.isEqualNode(@element)

    isLastElementChild:->
        @container.lastElementChild.isEqualNode(@element)

    on_dragenter:(e)=>
        if @isLastElementChild()
            return
        super
        updatePanel()

    on_dragover:(e)=>
        e.dataTransfer.dropEffect = 'none'
        e.stopPropagation()
        if not @isLastElementChild() or e.offsetX <= @element.clientWidth / 2
            $("#app_list").style.width = ''
            updatePanel()
            return

        container = $("#app_list")
        if not container
            return

        if item = container.firstElementChild
            item.style.marginLeft = "#{INSERT_INDICATOR_WIDTH}px"
            item.style.marginRight = ''
            app_list.setInsertAnchor(item)
            _lastHover = Widget.look_up(item.id)
        else
            container.style.width = "#{INSERT_INDICATOR_WIDTH}px"
            app_list.setInsertAnchor(null)
        updatePanel()


class SystemItem extends AppItem
    is_fixed_pos: true
    position: ['AppletNetwork', 'AppletDiskMount', 'AppletPower', 'AppletSound']
    constructor:(@id, icon, title)->
        super(@id, icon, title, $("#system"))
        @windowTitleWrap.style.display = 'none'
        @element.classList.add("AppletItem")
        @element.classList.add("Activator")
        @element.classList.remove("ClientGroup")
        # @imgWrap.classList.add("AppletItemImg")
        @imgContainer.classList.add("AppletItemImg")
        @img.classList.add("AppletItemImg")
        @imgHover.classList.add("AppletItemImg")
        @imgDark.classList.add("AppletItemImg")
        @img.draggable = false
        parentNode = $("#system")
        parentNode.appendChild(@element)
        @imgContainer.draggable = false
        @element.draggable = false
        for id in @position.slice(0).reverse()
            if item = $("##{id}")
                parentNode.insertBefore(item, parentNode.firstChild)
        parentNode.appendChild($("#system-tray")) if $("#system-tray")
        parentNode.appendChild($("#time")) if $("#time")

    isFirstElementChild:->
        $("#system").firstElementChild.isEqualNode(@element)

    isLastElementChild:->
        $("#system").lastElementChild.isEqualNode(@element)

    on_mouseover:=>
        super
        switch settings.displayMode()
            when DisplayMode.Efficient, DisplayMode.Classic
                @displayIcon()

    on_dragover:(e)=>
        e.stopPropagation()
        e.preventDefault()
        e.dataTransfer.dropEffect = 'none'
        _isDragging = false

        if not @isFirstElementChild() or e.offsetX >= @element.clientWidth / 2
            $("#app_list").style.width = ''
            updatePanel()
            return

        container = $("#app_list")
        if not container
            return

        if item = container.lastElementChild
            item.style.marginRight = "#{INSERT_INDICATOR_WIDTH}px"
            item.style.marginLeft = ''
            app_list.setInsertAnchor(item)
            _lastHover = Widget.look_up(item.id)
        else
            container.style.width = "#{INSERT_INDICATOR_WIDTH}px"
            app_list.setInsertAnchor(null)
        updatePanel()

    on_dragenter:(e)=>
        if @isFirstElementChild()
            return
        super
        updatePanel()


class PostfixedItem extends FixedItem
    constructor:(@id, icon, title)->
        super(@id, icon, title, $("#post_fixed"))
        @imgContainer.draggable = false


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

    on_mouseup: (e)=>
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
        m = new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem(1, _("_View as analog")),
            new MenuItem(2, _("_Time settings"))
        )
        m.unregisterHook(handleMenuUnregister)
        m.addListener(@on_itemselected).showMenu(
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

    on_mouseup: (e) =>
        super
        if e.button != 0
            return
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

    on_mouseup: (e) =>
        super
        if e.button != 0
            return
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
