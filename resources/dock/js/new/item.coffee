ENTRY_MANAGER_NAME = "dde.dock.EntryManager"

itemDBus = (path)->
    name: ENTRY_MANAGER_NAME
    path: path
    interface: "dde.dock.EntryProxyer"

propertiesDBus = (path)->
    name: ENTRY_MANAGER_NAME
    path: path
    interface: "org.freedesktop.DBus.Properties"


class Item extends Widget
    constructor:(@id, @icon, @container)->
        super()
        @imgWarp = create_element(tag:'div', class:"imgWarp", @element)
        @img = create_img(class:"AppItemImg", @imgWarp)
        @img.src = @icon || NOT_FOUND_ICON
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
    constructor:(@id, @dbus, @container)->
        if @dbus.Icon.indexOf("data:") != -1 or @dbus.Icon[0] == '/' or @dbus.Icon.indexOf("file://") != -1
            @icon = @dbus.Icon
        else
            @icon = DCore.get_theme_icon(@dbus.Icon, 48)

        super(@id, @icon, @dbus.Tooltip, null)
        $("#app_list").appendChild(@element)

        if app_list._insert_anchor_item
            app_list.append(@)
        else
            app_list.append_app_item?(@)

        @properties = get_dbus("session", propertiesDBus(@id))
        @properties.connect("PropertiesChanged", (info, d, a)->
            for own k, v of d
                console.log("properties updated: Key: #{k}, Value:#{v}")
                # @dbus[k] = v
        )

    on_mouseover:(e)=>
        super

    on_mouseout:(e)=>
        super

    on_rightclick:(e)=>
        super
        console.log("rightclick")
        xy = get_page_xy(@element)
        # @dbus.ContextMenu(
        #     xy.x + @element.clientWidth / 2,
        #     xy.y + OFFSET_DOWN,
        # )

    on_click:(e)=>
        super
        # @dbus.Activate(0,0)
