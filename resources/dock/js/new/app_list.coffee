class AppList
    @expand_panel_id: null
    constructor: (@id) ->
        @element = $("#app_list")
        @element.classList.add("AppList")
        @insert_indicator = create_element(tag:"div", class:"InsertIndicator")
        @_insert_anchor_item = null
        @is_insert_indicator_shown = false

    append: (c)->
        if @_insert_anchor_item and @_insert_anchor_item.element.parentNode == @element
            @element.insertBefore(c.element, @_insert_anchor_item.element)
            DCore.Dock.insert_apps_position(c.app_id, @_insert_anchor_item.app_id)
            @_insert_anchor_item = null
            @hide_indicator()
        else
            @append_app_item(c)
            if @_insert_anchor_item == null
                DCore.Dock.insert_apps_position(c.app_id, null)
        run_post(calc_app_item_size)

    append_app_item: (c)->
        @element.appendChild(c.element)

    record_last_over_item: (item)->
        @_insert_anchor_item = item

    do_drop: (e)=>
        e.stopPropagation()
        e.preventDefault()
        if dnd_is_desktop(e)
            path = e.dataTransfer.getData("text/uri-list").substring("file://".length).trim()
            DCore.Dock.request_dock(decodeURI(path))
        else if dnd_is_deepin_item(e) and @insert_indicator.parentNode == @element
            id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
            item = Widget.look_up(id) or Widget.look_up("le_"+id)
            item.flash(0.5)
            @append(item)
        @hide_indicator()
        calc_app_item_size()
        # update_dock_region()

    do_dragover: (e) =>
        e.preventDefault()
        e.stopPropagation()
        min_x = get_page_xy($("#show_launcher"), 0, 0).x
        max_x = get_page_xy($("#app_list").lastChild.previousSibling, 0, 0).x
        if e.screenX > min_x and e.screenX < max_x
            if dnd_is_deepin_item(e) or dnd_is_desktop(e)
                e.dataTransfer.dropEffect="copy"
                # n = e.x / (ITEM_WIDTH * ICON_SCALE)
                @show_indicator(e.x, e.dataTransfer.getData(DEEPIN_ITEM_ID))
                # if n > 1  # skip the show_launcher
                #     @show_indicator(e.x, e.dataTransfer.getData(DEEPIN_ITEM_ID))
                # else
                #     @hide_indicator()

    do_dragleave: (e)=>
        @hide_indicator()
        e.stopPropagation()
        e.preventDefault()
        if dnd_is_deepin_item(e) or dnd_is_desktop(e)
            calc_app_item_size()
            # update_dock_region()

    do_dragenter: (e)=>
        e.stopPropagation()
        e.preventDefault()
        min_x = get_page_xy($("#show_launcher"), 0, 0).x
        max_x = get_page_xy($("#app_list").lastChild.previousSibling, 0, 0).x
        if e.screenX > min_x and e.screenX < max_x
            DCore.Dock.require_all_region()

    swap_item: (src, dest)->
        swap_element(src.element, dest.element)
        DCore.Dock.swap_apps_position(src.app_id, dest.app_id)

    hide_indicator: ->
        if @insert_indicator.parentNode == @element
            @element.removeChild(@insert_indicator)
            @is_insert_indicator_shown = false
            clearTimeout(AppList.expand_panel_id)

    show_indicator: (x, try_insert_id)->
        if @is_insert_indicator_shown
            return
        @insert_indicator.style.width = ICON_SCALE * ICON_WIDTH
        @insert_indicator.style.height = ICON_SCALE * ICON_HEIGHT
        margin_top = (ITEM_HEIGHT - ICON_HEIGHT - BOARD_IMG_MARGIN_BOTTOM) * ICON_SCALE
        @insert_indicator.style.marginTop = margin_top

        return if @_insert_anchor_item?.app_id == try_insert_id

        if @_insert_anchor_item and get_page_xy(@_insert_anchor_item.img).x < x
            @_insert_anchor_item = @_insert_anchor_item.next()
            return if @_insert_anchor_item?.app_id == try_insert_id
        else
            return if @_insert_anchor_item?.prev()?.app_id == try_insert_id

        if @_insert_anchor_item
            @element.insertBefore(@insert_indicator, @_insert_anchor_item.element)
        else
            @element.appendChild(@insert_indicator)

        @is_insert_indicator_shown = true
        AppList.expand_panel_id = setTimeout(->
            panel.set_width(panel.width())
            panel.redraw()
        , 50)

app_list = new AppList("app_list")
