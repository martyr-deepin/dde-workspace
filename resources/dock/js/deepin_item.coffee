class Applet extends Item
    is_fixed_pos: false
    constructor: (@id, icon, title, @container)->
        super
        @type = ITEM_TYPE_APPLET

        @indicatorWrap = create_element(tag:'div', class:"indicatorWrap", @element)
        @openingIndicator = create_img(src:OPENING_INDICATOR, class:"indicator OpeningIndicator", @indicatorWrap)
        @openIndicator = create_img(src:OPEN_INDICATOR, class:"indicator OpenIndicator", @indicatorWrap)
        @openIndicator.style.display = 'none'

    on_mouseover: (e) =>
        super
        Preview_close_now()
        clearTimeout(hide_id)

    on_mouseout: (e)=>
        super
        if Preview_container.is_showing
            __clear_timeout()
            clearTimeout(tooltip_hide_id)
            DCore.Dock.require_all_region()
            normal_mouseout_id = setTimeout(->
                calc_app_item_size()
                if debugRegion
                    console.warn("[Applet.on_mouseout] update_dock_region")
                update_dock_region()
            , 1000)
        else
            calc_app_item_size()
            if debugRegion
                console.warn("[Applet.on_mouseout] update_dock_region")
            update_dock_region()
            setTimeout(->
                # DCore.Dock.update_hide_mode()
                hideStatusManager.updateState()
            , 500)


class FixedItem extends Applet
    is_fixed_pos: true
    __show: false
    constructor:(@id, icon, title, @container)->
        super
        @img.draggable = false

    show: (v)->
        @__show = v
        if @__show
            @openIndicator.style.display = ""
        else
            @openIndicator.style.display = "none"

    set_status: (status)=>
        @show(status)

    on_dragover:(e)=>
        super
        e.dataTransfer.dropEffect = 'none'
        _isDragging = false

    on_dragenter:(e)=>
        super
        updatePanel()


class PrefixedItem extends FixedItem
    constructor:(@id, icon, title)->
        super(@id, icon, title, $("#pre_fixed"))
        @imgContainer.draggable = false
        # $("#pre_fixed").appendChild(@element)

    isFirstElementChild:->
        @container.firstElementChild.isEqualNode(@element)

    isLastElementChild:->
        @container.lastElementChild.isEqualNode(@element)

    on_dragenter:(e)=>
        if @isLastElementChild()
            return
        super
        updatePanel()

    on_dragover:(e)=>
        e.dataTransfer.dropEffect = 'none'
        e.stopPropagation()
        if not @isLastElementChild() or e.offsetX <= @element.clientWidth / 2
            $("#app_list").style.width = ''
            updatePanel()
            return

        container = $("#app_list")
        if not container
            return

        if item = container.firstElementChild
            item.style.marginLeft = "#{INSERT_INDICATOR_WIDTH}px"
            item.style.marginRight = ''
            app_list.setInsertAnchor(item)
            _lastHover = Widget.look_up(item.id)
        else
            container.style.width = "#{INSERT_INDICATOR_WIDTH}px"
            app_list.setInsertAnchor(null)
        updatePanel()


class SystemItem extends AppItem
    is_fixed_pos: true
    position: ['AppletNetwork', 'AppletDiskMount', 'AppletSound', 'AppletPower']
    constructor:(@id, icon, title)->
        super(@id, icon, title, $("#system"))
        @windowTitleWrap.style.display = 'none'
        @element.classList.add("AppletItem")
        @element.classList.add("Activator")
        @element.classList.remove("ClientGroup")
        # @imgWrap.classList.add("AppletItemImg")
        @imgContainer.classList.add("AppletItemImg")
        @img.classList.add("AppletItemImg")
        @imgHover.classList.add("AppletItemImg")
        @imgDark.classList.add("AppletItemImg")
        @img.draggable = false
        parentNode = $("#system")
        parentNode.appendChild(@element)
        @imgContainer.draggable = false
        @element.draggable = false
        @imgWrap.draggable = false
        for id in @position.slice(0).reverse()
            if item = $("##{id}")
                parentNode.insertBefore(item, parentNode.firstChild)
        parentNode.appendChild($("#system-tray")) if $("#system-tray")
        parentNode.appendChild($("#time")) if $("#time")

    change_icon:(src)->
        if not (src.substring(0, 7) == "file://" || src.substring(0, 10) == "data:image")
            icon_size = 48
            switch settings.displayMode()
                when DisplayMode.Fashon
                    icon_size = 48
                when DisplayMode.Efficient
                    icon_size = 16
                when DisplayMode.Classic
                    icon_size = 16
            console.warn("#{@id} icon size is #{icon_size}")
            src = DCore.get_theme_icon(src, icon_size)
            console.warn("#{@id} get icon: #{src}")
        console.warn("#{@id} change icon src to: #{src}")
        @img.src = src
        @img.onload = =>
            @imgHover.src = bright_image(@img, 40)
            @imgDark.src = bright_image(@img, -40)

    isFirstElementChild:->
        $("#system").firstElementChild.isEqualNode(@element)

    isLastElementChild:->
        $("#system").lastElementChild.isEqualNode(@element)

    on_mouseover:=>
        super
        switch settings.displayMode()
            when DisplayMode.Efficient, DisplayMode.Classic
                @displayIcon()

    on_dragover:(e)=>
        e.stopPropagation()
        e.preventDefault()
        e.dataTransfer.dropEffect = 'none'
        _isDragging = false

        if not @isFirstElementChild() or e.offsetX >= @element.clientWidth / 2
            $("#app_list").style.width = ''
            updatePanel()
            return

        container = $("#app_list")
        if not container
            return

        if item = container.lastElementChild
            item.style.marginRight = "#{INSERT_INDICATOR_WIDTH}px"
            item.style.marginLeft = ''
            app_list.setInsertAnchor(item)
            _lastHover = Widget.look_up(item.id)
        else
            container.style.width = "#{INSERT_INDICATOR_WIDTH}px"
            app_list.setInsertAnchor(null)
        updatePanel()

    on_dragenter:(e)=>
        if @isFirstElementChild()
            return
        super
        updatePanel()


class PostfixedItem extends FixedItem
    constructor:(@id, icon, title)->
        super(@id, icon, title, $("#post_fixed"))
        @imgContainer.draggable = false
