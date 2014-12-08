class Clock
    @Type: {Digit:0, Analog:1, Tray:2}
    constructor:(@setting)->

    show:->
        if @time.style.display == 'none'
            @time.style.display = ''

    hide:->
        if @time.style.display != 'none'
            @time.style.display = 'none'

    @openDateAndTimeSettingModle:->
        try
            sysSettings = get_dbus('session', "com.deepin.dde.ControlCenter", "ShowModule")
        catch e
            console.log e
            sysSettings = null
        sysSettings?.ShowModule("date_time")


class ClockWith24Hour extends Clock
    constructor:(setting)->
        super(setting)
        @use24hour = @setting.Use24HourDisplay

    setUse24Hour:(use24hour)->
        @use24hour = use24hour
