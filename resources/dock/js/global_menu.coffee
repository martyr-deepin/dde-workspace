class GlobalMenu
    constructor:->
        @plugins = {}

    showMenu:(@x, y)->
        @menu?.destroy()
        @menu = null
        items = [
            new RadioBoxMenuItem('dockHideMode:radio:keep-showing', _("Keep _showing")),
            new RadioBoxMenuItem('dockHideMode:radio:keep-hidden', _("Keep _hidden"))
            # new RadioBoxMenuItem('dockHideMode:radio:auto-hide', _("_Auto hide")),
            new RadioBoxMenuItem('dockHideMode:radio:smart-hide', _("_Smart hide")),
        ]
        try
            dbus = DCore.DBus.session("dde.dock.entry.AppletManager")
            if dbus and not @plugins["deepinAppletManager"]
                @plugins["deepinAppletManager"] = dbus
        catch e
            console.warn e
            delete @plugins["deepinAppletManager"]
        hideMode = settings.hideMode()
        if hideMode == HideMode.SmartHide
            hideMode = hideMode - 1
        items[hideMode].setChecked(true)
        @menu = new Menu(DEEPIN_MENU_TYPE.NORMAL)
        displayModes = [
            new RadioBoxMenuItem("dockDisplayMode:radio:fashion", _("_Fashion mode")),
            new RadioBoxMenuItem("dockDisplayMode:radio:efficient", _("_Efficient mode")),
            new RadioBoxMenuItem("dockDisplayMode:radio:classic", _("_Classic mode"))
        ]
        displayModes[settings.displayMode()].setChecked(true)
        @menu.append.apply(@menu, displayModes)
        @menu.addSeparator()
        @menu.append.apply(@menu, items)

        if Object.keys(@plugins).length > 0
            @menu.addSeparator()
            @menu.append(new MenuItem("deepinAppletManager", _("Notification area settings")))

        _isRightclicked = true
        # @menu.addSeparator().append(new MenuItem("dockSetting", _("_Dock setting")))
        @menu.addListener(@on_itemselected).showMenu(@x, y)
        @menu.unregisterHook(handleMenuUnregister)

    on_itemselected:(id)=>
        info = id.split(":")
        groupName = info[0]
        realId = info[2] || null
        switch groupName
            when "dockHideMode"
                settings.setHideMode(HideModeNameMap[realId])
            when "dockDisplayMode"
                for own k, v of $DBus
                    item = Widget.look_up(k)
                    if item and item.isApp?() and item.isActive?()
                        item.hide_open_indicator()

                systemTray?.hideAllIcons()
                settings.setDisplayMode(DisplayModeNameMap[realId])
            when "deepinAppletManager"
                dbus = @plugins[groupName]
                if not dbus
                    console.warn("cannot get dbus of #{groupName}")
                    return
                dbus.ShowSettingWindow(@x)
            when "dockSetting"
                # TODO:
                # toggle dock setting panel.
                console.log("toggle dock setting panel")

        _isRightclicked = false
        @menu.unregister()
        @menu = null
