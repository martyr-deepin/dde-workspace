class DigitClock extends Clock
    constructor:(setting, parent)->
        super(setting)
        @type = Clock.Type.Digit
        @time = create_element('div', 'clock DigitClockTime', parent)
        @digitWrap = create_element(tag:"div", class:"digitWrap", @time)
        @hourHeight = create_element(tag:"div", class:"timeNumber", @digitWrap)
        @loadNumber(@hourHeight, "big", 0, 2)
        @hourHeightNumber = @hourHeight.firstElementChild

        @hourLow = create_element(tag:"div", class:"timeNumber hourLow", @digitWrap)
        @loadNumber(@hourLow, "big")
        @hourLowNumber = @hourLow.firstElementChild

        wrap = create_element(tag:"div", class:"minAndAPM", @digitWrap)

        minWrap = create_element(tag:"div", class:"minWrap", wrap)
        @minHeight = create_element(tag:"div", minWrap)
        @loadNumber(@minHeight, "small")
        @minHeightNumber = @minHeight.firstElementChild

        @minLow = create_element(tag:"div", class:"minLow", minWrap)
        @loadNumber(@minLow, "small", )
        @minLowNumber = @minLow.firstElementChild

        apm = create_element(tag:"div", class:"amp", wrap)
        @am = create_img(src:"js/plugins/time/img/am.png", style:"display:none", apm)
        @pm = create_img(src:"js/plugins/time/img/pm.png", style:"display:none", apm)

    loadNumber:(p, type, l=0, h=9)->
        for i in [l..h]
            create_img(src:"js/plugins/time/img/#{type}#{i}.png", style:"display:none", p)

    update:->
        now = new Now()
        if @setting.Use24HourDisplay
            hour = now.hour(24, true)
            if @am.style.display != 'none'
                @am.style.display = 'none'
            if @pm.style.display != 'none'
                @pm.style.display = 'none'
        else
            hour = now.hour(12, true)
            if now.isMorning()
                if @pm.style.display != 'none'
                    @pm.style.display = 'none'
                if @am.style.display == 'none'
                    @am.style.display = ''
            else
                if @am.style.display != 'none'
                    @am.style.display = 'none'
                if @pm.style.display == 'none'
                    @pm.style.display = ''
        @hourHeightNumber.style.display = 'none'
        @hourHeightNumber = @hourHeight.children[parseInt(hour[0])]
        @hourHeightNumber.style.display = ''

        @hourLowNumber.style.display = 'none'
        @hourLowNumber = @hourLow.children[parseInt(hour[1])]
        @hourLowNumber.style.display = ''

        min = now.min()
        @minHeightNumber.style.display = 'none'
        @minHeightNumber = @minHeight.children[parseInt(min[0])]
        @minHeightNumber.style.display = ''

        @minLowNumber.style.display = 'none'
        @minLowNumber = @minLow.children[parseInt(min[1])]
        @minLowNumber.style.display = ''
