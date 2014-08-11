class GlobalMenu
    constructor:->
        @plugins = {}

    showMenu:(x, y)->
        @menu?.destroy()
        @menu = null
        items = [
            new RadioBoxMenuItem('dockHideMode:radio:keep-showing', _("keep _showing")),
            new RadioBoxMenuItem('dockHideMode:radio:keep-hidden', _("keep _hidden"))
            new RadioBoxMenuItem('dockHideMode:radio:auto-hide', _("_auto hide")),
        ]
        try
            dbus = DCore.DBus.session("dde.dock.entry.AppletManager")
            if dbus and not @plugins["deepinAppletManager"]
                @plugins["deepinAppletManager"] = dbus
        catch e
            console.warn e
            @plugins["deepinAppletManager"]
        # console.log(settings.hideMode())
        items[settings.hideMode()].setChecked(true)
        @menu = new Menu(DEEPIN_MENU_TYPE.NORMAL)
        @menu.append.apply(@menu, items)

        if Object.keys(@plugins).length > 0
            @menu.addSeparator()

        for groupName, dbus of @plugins
            infos = JSON.parse(dbus.appletInfoList)
            for info in infos
                @menu.append(new CheckBoxMenuItem("#{groupName}:checkbox:#{info[0]}", info[1]).setChecked(info[2]))

        # console.log("showmenu:#{@menu.menu.menuJsonContent}")
        @menu.addListener(@on_itemselected).showMenu(x, y)
        @menu.unregisterHook(handleMenuUnregister)

    on_itemselected:(id)=>
        info = id.split(":")
        groupName = info[0]
        realId = info[2]
        console.log("globalMenu: groupName: #{groupName}, realId: #{realId}")
        switch groupName
            when "dockHideMode"
                settings.setHideMode(HideModeNameMap[realId])
            when "deepinAppletManager"
                dbus = @plugins[groupName]
                if not dbus
                    console.warn("cannot get dbus of #{groupName}")
                    return
                dbus.ToggleApplet(realId)

        _isRightclicked = false
        @menu.unregister()
        @menu = null
