HideState =
    Showing: 0
    Shown: 1
    Hidding: 2
    Hidden: 3


class HideStatusManager
    constructor: (mode)->
        if mode == HideMode.KeepHidden
            @state = HideState.Hidden
        else
            @state = HideState.Shown
        @dbus = DCore.DBus.session_object("com.deepin.daemon.Dock", "/dde/dock/HideStateManager", "dde.dock.HideStateManager")
        @dbus.connect("StateChanged", (state)=>
            switch settings.hideMode()
                when HideMode.KeepShowing
                    if state == HideState.Showing
                        @changeToShow()
                when HideMode.KeepHidden
                    switch state
                        when HideState.Showing
                            @changeToShow()
                        when HideState.Hidding
                            @changeToHide()
                when HideMode.AutoHide
                    switch state
                        when HideState.Showing
                            @changeToShow()
                        when HideState.Hidding
                            @changeToHide()

            clearTimeout(changeDockRegionTimer)
            changeDockRegionTimer = setTimeout(@changeDockRegion, 400)

            console.log("StateChanged: #{state}")
            @state = state
        )

    setState: (state)->
        @dbus.SetState(state)

    updateState:()->
        @dbus.UpdateState()

    changeMode:(mode)->
        console.log("changeMode is invoked")
        @updateState()

    changeState: (state, cw, panel)->
        # update_dock_region()
        # DCore.Dock.require_all_region()
        _CW.style.webkitTransform = cw
        $("#panel").style.webkitTransform = panel

    changeToHide:()->
        console.log("changeToHide: change to hide")
        @changeState(HideState.Hidding, "", "")

    changeToShow:()->
        console.log("changeToShow: change to show")
        @changeState(HideState.Showing, "translateY(0)", "translateY(0)")

    changeDockRegion: =>
        console.log("changeDockRegion")
        console.warn("changeDockRegion")
        if @state == HideState.Showing
            @setState(HideState.Shown)
        else if @state == HideState.Hidding
            @setState(HideState.Hidden)

        return
        regionHeight = DOCK_HEIGHT
        console.log($("#panel").style.webkitTransform)
        if $("#panel").style.webkitTransform == ""
            regionHeight = 0
            console.warn("hide dock region")
            # update_dock_region(null, regionHeight)

        console.log("set workarea height to #{regionHeight}")
        # update_dock_region(null, regionHeight)
        # DCore.Dock.change_workarea_height(regionHeight)
