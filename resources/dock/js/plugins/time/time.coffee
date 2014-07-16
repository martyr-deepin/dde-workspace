class Time extends SystemItem
    @weekday: [_("Sun"), _("Mon"), _("Tue"), _("Wed"), _("Thu"), _("Fri"), _("Sat")]
    constructor:->
        super
        @time = create_element('div', 'DigitClockTime', @imgWarp)

        for name in ['hourHeight', 'hourLow', 'minHeight', 'minLow']
            @loadBit(name)

        @timeContent = create_element(tag:'div', id:"timeContent")
        @element.insertBefore(@timeContent, @imgWarp)

        @element.addEventListener("mouseover", @on_mouseover)
        @element.addEventListener("mouseout", @on_mouseout)
        @element.addEventListener("click", @on_mouseup)

        @update_time()
        @update_id = setInterval(@update_time, 1000)
        @type = DIGIT_CLOCK['type']
        @indicatorWarp.style.display = 'none'

    loadBit:(name)->
        this[name] = create_element(tag:'div', class:'timeNumber', @time)
        @loadNumber(this[name])
        this["#{name}Number"] = this[name].firstElementChild

    loadNumber:(p)->
        for i in [0..9]
            create_img(src:"js/plugins/time/img/#{i}.png", style:"display:none", p)

    isNormal:->
        # TODO
        false

    isNormalApplet: ->
        # TODO
        false

    isRuntimeApplet: ->
        true

    on_rightclick:(e)->
        DCore.Dock.set_is_hovered(false)
        update_dock_region($("#container").clientWidth)
        e.preventDefault()
        e.stopPropagation()
        Preview_close_now()

    on_mouseover:=>
        super
        # @set_tooltip((new Date()).toLocaleDateString())

    on_mouseout:=>
        super

    on_mouseup:(e)=>
        super
        if e.button != 0
            return
        try
            sysSettings = get_dbus('session', "com.deepin.dde.ControlCenter", "ShowModule")
        catch e
            console.log e
            sysSettings = null
        sysSettings?.ShowModule("date_time") if sysSettings

    update_time: =>
        switch settings.displayMode()
            when DisplayMode.Classic
                @update_time_for_classic_mode()
            when DisplayMode.Modern
                @update_time_for_modern_mode()

    update_time_for_classic_mode: =>
        d = new Date()
        @timeContent.textContent = ""

        # TODO: week
        if true
            @timeContent.textContent += "#{Time.weekday[d.getDay()]} "

        @timeContent.textContent += "#{d.toLocaleDateString()}"

        hour = @hour(24, true)
        @timeContent.textContent += " #{hour}"

        min = @min()
        @timeContent.textContent += ":#{min}"

    update_time_for_modern_mode:=>
        hour = @hour(24, true)
        @hourHeightNumber.style.display = 'none'
        @hourHeightNumber = @hourHeight.children[parseInt(hour[0])]
        @hourHeightNumber.style.display = ''

        @hourLowNumber.style.display = 'none'
        @hourLowNumber = @hourLow.children[parseInt(hour[1])]
        @hourLowNumber.style.display = ''
        @hourLowNumber.style.marginLeft = '1px'
        @hourLowNumber.style.marginRight = '2px'

        min = @min()
        @minHeightNumber.style.display = 'none'
        @minHeightNumber = @minHeight.children[parseInt(min[0])]
        @minHeightNumber.style.display = ''
        @minHeightNumber.style.marginLeft = '2px'
        @minHeightNumber.style.marginRight = '1px'

        @minLowNumber.style.display = 'none'
        @minLowNumber = @minLow.children[parseInt(min[1])]
        @minLowNumber.style.display = ''

    force2bit: (n)->
        if n < 10 then "0#{n}" else "#{n}"

    hour: (max_hour=24, twobit=false)->
        hour = new Date().getHours()
        switch max_hour
            when 12
                if twobit then @force2bit(hour % 12) else "#{hour % 12}"
            when 24
                if twobit then @force2bit(hour) else "#{hour}"

    min: (twobit=true) ->
        min = new Date().getMinutes()
        if twobit then @force2bit(min) else "#{min}"

    year:->
        new Date().getFullYear()

    month:->
        new Date().getMonth() + 1

    weekday:->
        new Date().getDay()

    date:->
        new Date().getDate()
