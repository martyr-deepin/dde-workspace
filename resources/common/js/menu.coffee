###
class Menu
    constructor: (item...)->
        @checkableMenu = false
        @singleCheck = false
        @items = []
        if item.length == 1 and Array.isArray(item[0])
            Menu::append.apply(@, item[0])
        else
            Menu::append.apply(@, item)

    append: (item...)->
        for i in [0...item.length]
            @items.push(item[i])
        @

    addSeparator: ->
        @append(new MenuSeparator)

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
    constructor: (@itemId, @itemText, @itemIcon='', @itemIconHover='', @isActive=true, @itemSubMenu=new Menu)->
        @isCheckable = false
        @checked = false

    setIcon: (icon)->
        @itemIcon = icon
        @

    setHoverIcon: (icon)->
        @itemIconHover = icon
        @

    setSubMenu: (subMenu)->
        @itemSubMenu = subMenu
        @

    setActive: (isActive)->
        @isActive = isActive
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


class MenuHandler
    constructor: (@menu)->
        for dump in [0...10]
            try
                @dbus = DCore.DBus.session_object("com.deepin.menu", "/com/deepin/menu", "com.deepin.menu.Menu")
                break
            catch e
                echo "constructor: #{e}"
        if not @dbus?
            throw "Connecting Menu DBUS failed"

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

    listenItemSelected: (callback)->
        try
            @dbus.connect("ItemInvoked", callback)
        catch e
            echo "listenItemSelected: #{e}"

    showMenu: (x, y)->
        @dbus.ShowMenu(x, y, JSON.stringify(@menu))

    showDockMenu: (x, y, ori)->
        @dbus.ShowDockMenu(x, y, JSON.stringify(@menu), ori)

    toString: ->
        JSON.stringify(@menu)


create_menu = (type, items...)->
    switch type
        when MENU_TYPE_NORMAL
            new MenuHandler(new Menu(items))
        when MENU_TYPE_CHECKBOX
            new MenuHandler(new CheckBoxMenu(items))
        when MENU_TYPE_RADIOBOX
            new MenuHandler(new RadioBoxMenu(items))
###

class Menu
    constructor: (items...)->
        @items = []
        if items.length == 1 and Array.isArray(items[0])
            Menu::append.apply(@, items[0])
        else
            Menu::append.apply(@, items)

    append: (items...)->
        for i in [0...items.length]
            @items.push(items[i].raw())
        @

    addSeparator: ->
        @append(new MenuSeparator)

    bind: (item)=>
        item.element.contextMenu = build_menu(@items)


class MenuItem
    constructor: (id, text)->
        if typeof id != 'number'
            @item = [parseInt(id), text, true]
        else
            @item = [id, text, true]

    setActive: (actived)->
        @item[2] = actived
        @

    raw: ->
        @item


class MenuSeparator
    constructor: ->
    raw: ->
        []

create_menu = (type, items...) ->
    new Menu(items)
