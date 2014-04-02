class GlobalMenu
    constructor:->
        @map =
            "keep-showing": 0
            "keep-hidden": 1
            "auto-hide": 2

    showMenu:(x, y)->
        @menu?.destroy()
        @menu = null
        items = [
            new RadioBoxMenuItem('keep-showing', _("keep _showing")),
            new RadioBoxMenuItem('keep-hidden', _("keep _hidden"))
            new RadioBoxMenuItem('auto-hide', _("_auto hide")),
        ]
        # console.log(settings)
        items[@map[settings.hideMode()]].setChecked(true)
        @menu = new Menu(DEEPIN_MENU_TYPE.RADIOBOX)
        @menu.append.apply(@menu, items)
        # console.log("showmenu:#{@menu.menu.menuJsonContent}")
        @menu.addListener(@on_itemselected).showMenu(x, y)

    on_itemselected:(id)->
        settings.setHideMode(id)
