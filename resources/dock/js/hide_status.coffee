HideState =
    Showing: 0
    Shown: 1
    Hidding: 2
    Hidden: 3


HideStateMap = ["Showing", "Shown", "Hidding", "Hidden"]


class HideStatusManager
    constructor: (mode)->
        if mode == HideMode.KeepHidden
            @state = HideState.Hidden
        else
            @state = HideState.Shown
        try
            @dbus = DCore.DBus.session_object("com.deepin.daemon.Dock", "/dde/dock/HideStateManager", "dde.dock.HideStateManager")
        catch e
            console.log(e)
            @dbus = null

        @dbus?.connect("StateChanged", (state)=>
            if DCore.Dock.is_hovered()
                return

            switch settings.hideMode()
                when HideMode.KeepShowing
                    if state == HideState.Showing
                        @changeToShow()
                when HideMode.KeepHidden
                    switch state
                        when HideState.Showing
                            update_dock_region()
                            @changeToShow()
                        when HideState.Hidding
                            @changeToHide()
                when HideMode.AutoHide
                    switch state
                        when HideState.Showing
                            update_dock_region()
                            @changeToShow()
                        when HideState.Hidding
                            @changeToHide()

            @state = state
            clearTimeout(changeDockRegionTimer)
            changeDockRegionTimer = setTimeout(@changeDockRegion, 400)

            console.log("StateChanged: #{HideStateMap[state]}")
        )

    setState: (state)->
        @dbus?.SetState(state)

    updateState:()->
        @dbus?.UpdateState()

    changeMode:(mode)->
        console.log("changeMode is invoked")
        @updateState()

    changeState: (state, cw, panel)->
        if DCore.Dock.is_hovered()
            console.warn("changeState dock is hovered")
            return
        _CW.style.webkitTransform = cw
        $("#panel").style.webkitTransform = panel

    changeToHide:()->
        console.log("changeToHide: change to hide")
        @changeState(HideState.Hidding, "", "")
        clearTimeout(@updateSystemTrayTiemr || null)
        systemTray?.hideAllIcons()
        $tooltip?.hide()

    changeToShow:()->
        console.log("changeToShow: change to show")
        @changeState(HideState.Showing, "translateY(0)", "translateY(0)")
        clearTimeout(@updateSystemTrayTiemr || null)
        @updateSystemTrayTiemr = setTimeout(->
            if not systemTray
                return
            if systemTray.isUnfolded
                # console.log("system tray is unfolded")
                systemTray.updateTrayIcon()
                systemTray.showAllIcons()
            else if systemTray.isShowing
                # console.log("system tray is showing")
                systemTray.on_mouseover()
            DCore.Dock.set_is_hovered(false)
        , 400)

    changeDockRegion: =>
        console.log("changeDockRegion")
        if @state == HideState.Showing
            @setState(HideState.Shown)
        else if @state == HideState.Hidding
            @setState(HideState.Hidden)

        # return
        regionHeight = DOCK_HEIGHT
        console.log("panel webkitTransform: #{$("#panel").style.webkitTransform}")
        if $("#panel").style.webkitTransform == ""
            regionHeight = 0
            console.warn("hide dock region")
            # update_dock_region(null, regionHeight)

        console.log("set workarea height to #{regionHeight}")
        update_dock_region(null, regionHeight)
        # c code handles workarea height
