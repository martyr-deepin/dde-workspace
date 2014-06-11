class Time extends SystemItem
    constructor:->
        super
        @time = create_element('div', 'DigitClockTime', @imgWarp)

        for name in ['hourHeight', 'hourLow', 'minHeight', 'minLow']
            @loadBit(name)

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

    on_mouseover:=>
        super
        @set_tooltip((new Date()).toLocaleDateString())

    on_mouseout:=>
        super

    on_mouseup:(e)=>
        super
        if e.button != 0
            return
        sysSettings = get_dbus('session', "com.deepin.dde.ControlCenter", "ShowModule")
        sysSettings.ShowModule("date_time") if sysSettings

    update_time: =>
        # @time.textContent = "#{@hour()}:#{@min()}"
        # console.log("#{@hour(24, true)}:#{@min()}")
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

