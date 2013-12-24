DEEPIN_MENU_NAME = "com.deepin.menu"
DEEPIN_MENU_PATH = "/com/deepin/menu"
DEEPIN_MENU_INTERFACE = "com.deepin.menu.Menu"
DEEPIN_MENU_MANAGER_INTERFACE = "com.deepin.menu.Manager"


DEEPIN_MENU_CORNER_DIRECTION=
    up: "up"
    down: "down"
    left: "left"
    right: "right"


class Menu
    constructor: (item...)->
        @x = 0
        @y = 0
        @isDockMenu = false
        @cornerDirection = DEEPIN_MENU_CORNER_DIRECTION.down
        if item.length == 1
            @menuJsonContent = new MenuContent(item[0])
        else
            @menuJsonContent = new MenuContent(item)

    append: (item...)->
        MenuContent::append.apply(@menuJsonContent, item)

    addSeparator: ->
        @menuJsonContent.addSeparator()

    toString: ->
        "{\"x\": #{@x}, \"y\": #{@y}, \"isDockMenu\": #{@isDockMenu}, \"cornerDirection\": \"#{@cornerDirection}\", \"menuJsonContent\": \"#{@menuJsonContent.toString().addSlashes()}\"}"


class MenuContent
    constructor: (item...)->
        @checkableMenu = false
        @singleCheck = false
        @items = []
        if item.length == 1 and Array.isArray(item[0])
            MenuContent::append.apply(@, item[0])
        else
            MenuContent::append.apply(@, item)

    append: (item...)->
        item.forEach((el) =>
            @items.push(el)
        )
        @

    addSeparator: ->
        @append(new MenuSeparator())

    toString:->
        JSON.stringify(@)


class CheckBoxMenu extends Menu
    constructor:->
        super
        @checkableMenu = true


class RadioBoxMenu extends CheckBoxMenu
    constructor:->
        super
        @singleCheck = true


class MenuItem
    constructor: (@itemId, @itemText, @itemIcon='', @itemIconHover='', @isActive=true, @itemSubMenu=new MenuContent)->
        @isCheckable = false
        @checked = false
        @itemIconInactive = ""
        @showCheckmark = true

    setIcon: (icon)->
        @itemIcon = icon
        @

    setHoverIcon: (icon)->
        @itemIconHover = icon
        @

    setInactiveIcon: (icon)->
        @itemIconInactive = icon
        @

    setSubMenu: (subMenu)->
        @itemSubMenu = subMenu.menuJsonContent
        @

    setActive: (isActive)->
        @isActive = isActive
        @

    setShowCheckmark: (showCheckmark)->
        @showCheckmark = showCheckmark
        @

    toString: ->
        JSON.stringify(@)


class CheckBoxMenuItem extends MenuItem
    constructor: (itemId, itemText, checked=false, isActive=true)->
        super(itemId, itemText, '', '', isActive)
        @isCheckable = true

    setChecked: (checked)->
        @checked = checked
        @


RadioBoxMenuItem = CheckBoxMenuItem


class MenuSeparator extends MenuItem
    constructor: ->
        super('', '')


get_dbus = (type, dbus_name, dbus_path, dbus_interface)->
    for dump in [0...10]
        try
            dbus = DCore.DBus["#{type.toLowerCase()}_object"](
                dbus_name, dbus_path, dbus_interface
            )
            return dbus

        if not dbus?
            return null


class MenuHandler
    constructor: (@menu)->

    append: (items...)->
        switch @menu.constructor.name
            when "Menu"
                Menu::append.apply(@menu, items)
            when "CheckBoxMenu"
                CheckBoxMenu::append.apply(@menu, items)
            when "RadioBoxMenuItem"
                RadioBoxMenuItem::append.apply(@menu, items)
        @

    addSeparator: ->
        @menu.addSeparator()
        @

    setDockMenuCornerDirection: (cornerDirection)->
        @menu.cornerDirection = cornerDirection

    # addListener: (callback)->
    #     try
    #         @dbus.connect("ItemInvoked", callback)
    #     catch e
    #         echo "listenItemSelected: #{e}"

    init_dbus: (x, y)->
        manager = get_dbus(
            "session",
            DEEPIN_MENU_NAME,
            DEEPIN_MENU_PATH,
            DEEPIN_MENU_MANAGER_INTERFACE
        )

        if not manager
            throw "get Menu Manager DBus failed"

        menu_dbus_path = manager.RegisterMenu_sync()
        # echo "menu path is: #{menu_dbus_path}"
        dbus = get_dbus(
            "session",
            DEEPIN_MENU_NAME,
            menu_dbus_path,
            DEEPIN_MENU_INTERFACE)

        if not dbus
            throw "get Menu DBus failed"

        dbus

    showMenu: (x, y, ori=null)->
        @menu.x = x
        @menu.y = y
        if ori != null
            @menu.isDockMenu = true
            @menu.cornerDirection = ori
        @init_dbus(x, y).ShowMenu("#{@menu}")

    toString: ->
        "#{@menu}"


create_menu = (type, items...)->
    switch type
        when MENU_TYPE_NORMAL
            new MenuHandler(new Menu(items))
        when MENU_TYPE_CHECKBOX
            new MenuHandler(new CheckBoxMenu(items))
        when MENU_TYPE_RADIOBOX
            new MenuHandler(new RadioBoxMenu(items))
