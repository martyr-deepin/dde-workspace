HideState =
    Showing: 0
    Shown: 1
    Hidding: 2
    Hidden: 3


HideStateMap = ["Showing", "Shown", "Hidding", "Hidden"]

Trigger =
    Show: 0
    Hide: 1


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

        @dbus?.connect("ChangeState", (trigger)=>
            if DCore.Dock.is_hovered() || _isRightclicked
                console.log("dock is hovered of contextmenu is shown")
                return

            switch trigger
                when Trigger.Show
                    clearTimeout(changeToHideTimer)
                    if @state == HideState.Shown
                        return
                    if debugRegion
                        console.warn("[ChangeState] update_dock_region")
                    update_dock_region()
                    @changeToShow()
                when Trigger.Hide
                    if @state == HideState.Hidden
                        return
                    if _dropped
                        clearTimeout(changeToHideTimer)
                        changeToHideTimer = setTimeout(=>
                            @changeToHide()
                            _dropped = false
                            changeToHideTimer = null
                        , 1000)
                    else
                        @changeToHide()
        )

        _CW.addEventListener("webkitTransitionEnd", (e)=>
            @changeDockRegion()
        )

    setState: (state)->
        @state = state
        @dbus?.SetState(state)

    updateState:()->
        @dbus?.UpdateState()

    changeMode:(mode)->
        @updateState()

    changeState: (state, cw, panel)->
        if DCore.Dock.is_hovered()
            return

        @setState(state)

        # clearTimeout(changeDockRegionTimer)
        # changeDockRegionTimer = setTimeout(@changeDockRegion, SHOW_HIDE_ANIMATION_TIME)

        _CW.style.webkitTransform = cw
        $("#panel").style.webkitTransform = panel
        switch settings.displayMode()
            when DisplayMode.Efficient, DisplayMode.Classic
                $("#trayarea").style.webkitTransform = cw

    changeToHide:()->
        @changeState(HideState.Hidding, "translateY(110%)", "translateY(100%)")
        clearTimeout(@updateSystemTrayTimer || null)
        systemTray?.hideAllIcons()
        $tooltip?.hide()

    updateTrayIcons: =>
        if not systemTray
            return
        if systemTray.isUnfolded
            systemTray.updateTrayIcon()
            systemTray.showAllIcons()
        else if systemTray.isShowing
            systemTray.minShow()
        DCore.Dock.set_is_hovered(false)

    changeToShow:()->
        @changeState(HideState.Showing, "translateY(0)", "translateY(0)")
        clearTimeout(@updateSystemTrayTimer || null)
        @updateSystemTrayTimer = setTimeout(@updateTrayIcons, SHOW_HIDE_ANIMATION_TIME)

    changeDockRegion: =>
        if @state == HideState.Showing
            @setState(HideState.Shown)
        else if @state == HideState.Hidding
            @setState(HideState.Hidden)

        regionHeight = DOCK_HEIGHT
        if $("#panel").style.webkitTransform == "translateY(100%)"
            regionHeight = 0

        if debugRegion
            console.warn("[HideStateManager.changeDockRegion] update_dock_region: #{regionHeight}")
        DCore.Dock.change_workarea_height(regionHeight)
        update_dock_region(null, regionHeight)
