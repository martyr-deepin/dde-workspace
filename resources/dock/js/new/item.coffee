class Item extends Widget
    constructor:(@id, icon, title, @container)->
        super()
        @imgWarp = create_element(tag:'div', class:"imgWarp", @element)
        @img = create_img(class:"AppItemImg", @imgWarp)
        @img.src = icon || NOT_FOUND_ICON
        @img.classList.add("ReflectImg")
        @img.style.pointerEvents = "auto"
        @img.addEventListener("mouseover", @on_mouseover)
        @img.addEventListener("mouseout", @on_mouseout)
        @img.addEventListener("click", @on_click)
        @img.addEventListener("contextmenu", @on_rightclick)

        calc_app_item_size()
        @tooltip = null
        @element.classList.add("AppItem")
        @element.draggable=true
        @container?.appendChild?(@element)

    set_tooltip: (text) ->
        if @tooltip == null
            # @tooltip = new ToolTip(@element, text)
            @tooltip = new ArrowToolTip(@element, text)
            @tooltip.set_delay_time(200)  # set delay time to the same as scale time
            return
        @tooltip.set_text(text)

    destroy_tooltip:->
        @tooltip?.hide()
        @tooltip?.destroy()
        @tooltip = null

    showTooltip:->
        @set_tooltip(@dbus.ToolTip)

    update_scale:->

    on_mouseover:(e)=>
        console.log("mouseover, require_all_region")
        DCore.Dock.require_all_region()
        @imgWarp.style.webkitTransform = 'translateY(-5px)'
        @imgWarp.style.webkitTransition = 'all 100ms'

    on_mouseout:(e)=>
        @imgWarp.style.webkitTransform = 'translateY(0px)'
        @imgWarp.style.webkitTransition = 'all 400ms'
        calc_app_item_size()

    on_rightclick:(e)=>
        e.preventDefault()
        e.stopPropagation()

    on_click:(e)=>
        e.preventDefault()
        e.stopPropagation()


class AppItem extends Item
    is_fixed_pos: false
    constructor:(@id, @icon, title, @container)->

        super

        if app_list._insert_anchor_item
            app_list.append(@)
        else
            app_list.append_app_item?(@)

        $DBus[@id]?.connect("DataChanged", (name, value)->
            console.log("#{name} is changed to #{value}")
        )

    on_mouseover:(e)=>
        super

    on_mouseout:(e)=>
        super

    on_rightclick:(e)=>
        super
        Preview_close_now()
        _lastCliengGroup?.embedWindows.hide?()
        console.log("rightclick")
        xy = get_page_xy(@element)

        menu =
            x: xy.x + @element.clientWidth / 2
            y: xy.y
            isDockMenu: true
            cornerDirection: DEEPIN_MENU_CORNER_DIRECTION.DOWN
            menuJsonContent:"#{$DBus[@id].Data[ITEM_DATA_FIELD.menu]}"

        menuJson = JSON.stringify(menu)

        # console.log(menuJson)

        manager = get_dbus(
            "session",
            name:DEEPIN_MENU_NAME,
            path:DEEPIN_MENU_PATH,
            interface:DEEPIN_MENU_MANAGER_INTERFACE
        )

        menu_dbus_path = manager.RegisterMenu_sync()
        # echo "menu path is: #{menu_dbus_path}"
        dbus = get_dbus(
            "session",
            name:DEEPIN_MENU_NAME,
            path:menu_dbus_path,
            interface:DEEPIN_MENU_INTERFACE)

        if dbus
            dbus.connect("ItemInvoked", @on_itemselected($DBus[@id]))
            dbus.ShowMenu(menuJson)

    on_itemselected: (d)->
        (id)->
            console.log("select id: #{id}")
            d.HandleMenuItem(parseInt(id))

    on_click:(e)=>
        super
        $DBus[@id].Activate(0,0)
