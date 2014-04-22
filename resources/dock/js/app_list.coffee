showIndicatorTimer = null
class AppList
    @expand_panel_id: null
    constructor: (@id) ->
        @element = $("#app_list")
        @element.classList.add("AppList")
        @element.addEventListener("dragenter", @do_dragenter)
        @element.addEventListener("dragover", @do_dragover)
        @element.addEventListener("dragleave", @do_dragleave)
        @element.addEventListener("drop", @do_drop)
        @element.draggable = true
        @insert_indicator = create_element(tag:"div", class:"InsertIndicator")
        @_insert_anchor_item = null
        @is_insert_indicator_shown = false

    append: (c)->
        if @_insert_anchor_item and @_insert_anchor_item.element.parentNode == @element
            @element.insertBefore(c.element, @_insert_anchor_item.element)
            @_insert_anchor_item = null
            @hide_indicator()
        else
            @append_app_item(c)
        run_post(calc_app_item_size)

    append_app_item: (c)->
        @element.appendChild(c.element)

    record_last_over_item: (item)->
        @_insert_anchor_item = item

    do_drop: (e)=>
        e.stopPropagation()
        e.preventDefault()
        console.log("do drop on app_list")
        if dnd_is_desktop(e)
            console.log("is desktop")
            path = e.dataTransfer.getData("text/uri-list").substring("file://".length).trim()
            id = get_path_name(path)
            t = create_element(tag:'div', name:id)
            console.log("insert tmp before insert_indicator")
            console.log(t)
            console.log(@insert_indicator)
            console.log(@insert_indicator.parentNode)
            if @insert_indicator.parentNode
                @element.insertBefore(t, @insert_indicator)
                dockedAppManager?.Dock(id, "", "", "")
        else if dnd_is_deepin_item(e) and @insert_indicator.parentNode == @element
            id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
            item = Widget.look_up(id) or Widget.look_up("le_"+id)
            @element.insertBefore(item.element, @insert_indicator)
            sortDockedItem()
            # @append(item)
        @hide_indicator()
        calc_app_item_size()

    do_dragover: (e) =>
        console.log("applist dragover")
        clearTimeout(cancelInsertTimer)
        e.preventDefault()
        e.stopPropagation()
        if dnd_is_deepin_item(e) or dnd_is_desktop(e)
            clearTimeout(showIndicatorTimer)
            try_insert_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
            e.dataTransfer.dropEffect="copy"
            step = 6
            x = e.x
            el = null
            y = if e.y > screen.height - DOCK_HEIGHT + ITEM_HEIGHT then e.y else e.y - ITEM_HEIGHT/2
            while 1
                x -= step
                el = document.elementFromPoint(x, y)
                return if not el
                if el.classList?.contains("AppItemImg")
                    id = el.parentNode.parentNode.parentNode.id
                    console.log(id)
                    if id == try_insert_id
                        return
                    break
                # else if el.tagName = "BODY"
                #     return
            x = e.x
            while 1
                x += step
                el = document.elementFromPoint(x, y)
                if el.classList.contains("AppItemImg")
                    break
                else if el.tagName == "BODY"
                    el = null
            el = el.parentNode.parentNode.parentNode if el
            if el.parentNode.id != "app_list"
                el = null
            if el == null or el.id != try_insert_id
                console.log(el)
                showIndicatorTimer = setTimeout(=>
                    @show_indicator(el, try_insert_id)
                , 100)

    do_dragleave: (e)=>
        clearTimeout(showIndicatorTimer)
        console.log("app_list dragleave")
        @hide_indicator()
        e.stopPropagation()
        e.preventDefault()
        if dnd_is_deepin_item(e) or dnd_is_desktop(e)
            cancelInsertTimer = setTimeout(-
                calc_app_item_size()
            , 100)
            # update_dock_region()

    do_dragenter: (e)=>
        console.log("applist dragenter")
        e.stopPropagation()
        e.preventDefault()
        DCore.Dock.require_all_region()
        # @do_dragover(e)

    swap_item: (src, dest)->
        swap_element(src.element, dest.element)
        items = []
        appList = $("#app_list")
        for i in [0...appList.children.length]
            child = appList.children[i]
            items.push(child.id)
        dockedAppManager.Sort(items)

    hide_indicator: ->
        if @insert_indicator.parentNode == @element
            console.log("remove Insert indicator")
            @element.removeChild(@insert_indicator)
            @is_insert_indicator_shown = false
            clearTimeout(AppList.expand_panel_id)

    show_indicator: (anchor, try_insert_id)->
        if @is_insert_indicator_shown
            return
        @insert_indicator.style.width = ICON_WIDTH
        @insert_indicator.style.height = ICON_HEIGHT

        return if anchor?.id == try_insert_id
        @is_insert_indicator_shown = true

        console.log("Insert Indicator")
        # console.log(@element)
        if anchor
            @element.insertBefore(@insert_indicator, anchor)
        else
            @element.appendChild(@insert_indicator)

        AppList.expand_panel_id = setTimeout(->
            panel.set_width(panel.width())
            panel.redraw()
        , 50)

app_list = new AppList("app_list")
