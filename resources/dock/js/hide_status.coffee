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
            if DCore.Dock.is_hovered() || _isRightclicked
                console.log("dock is hovered of contextmenu is shown")
                return

            switch state
                when HideState.Showing
                    clearTimeout(changeToHideTimer)
                    if debugRegion
                        console.warn("[HideStateManager.changeDockRegion] update_dock_region")
                    update_dock_region()
                    @changeToShow()
                when HideState.Hidding
                    if _dropped
                        clearTimeout(changeToHideTimer)
                        changeToHideTimer = setTimeout(=>
                            @changeToHide()
                            _dropped = false
                            changeToHideTimer = null
                        , 1000)
                    else
                        @changeToHide()

            @state = state
            console.log("StateChanged: #{HideStateMap[state]}")
        )

    setState: (state)->
        # console.log("set state to #{HideStateMap[state]}")
        @dbus?.SetState(state)

    updateState:()->
        @dbus?.UpdateState()

    changeMode:(mode)->
        console.log("changeMode is invoked")
        @updateState()

    changeState: (state, cw, panel)->
        if DCore.Dock.is_hovered()
            console.log("changeState dock is hovered")
            return
        _CW.style.webkitTransform = cw
        $("#panel").style.webkitTransform = panel
        switch settings.displayMode()
            when DisplayMode.Efficient, DisplayMode.Classic
                $("#trayarea").style.webkitTransform = cw

        clearTimeout(changeDockRegionTimer)
        changeDockRegionTimer = setTimeout(@changeDockRegion, SHOW_HIDE_ANIMATION_TIME)

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
                systemTray.minShow()
            DCore.Dock.set_is_hovered(false)
        , SHOW_HIDE_ANIMATION_TIME)

    changeDockRegion: =>
        console.log("changeDockRegion, #{HideStateMap[@state]}")
        if @state == HideState.Showing
            @setState(HideState.Shown)
        else if @state == HideState.Hidding
            @setState(HideState.Hidden)

        # return
        regionHeight = DOCK_HEIGHT
        console.log("panel webkitTransform: ##{$("#panel").style.webkitTransform}#")
        if $("#panel").style.webkitTransform == ""
            console.log("[HideStateManager.changeDockRegion] hide dock region")
            regionHeight = 0

        console.log("[HideStateManager.changeDockRegion] set workarea height to #{regionHeight}")
        if debugRegion
            console.warn("[HideStateManager.changeDockRegion] update_dock_region: #{regionHeight}")
        DCore.Dock.change_workarea_height(regionHeight)
        update_dock_region(null, regionHeight)
