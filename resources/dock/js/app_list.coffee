showIndicatorTimer = null
class AppList
    @expand_panel_id: null
    constructor: (@id) ->
        @element = $("#app_list")
        @element.classList.add("AppList")
        @element.addEventListener("dragenter", @on_dragenter)
        @element.addEventListener("dragover", @on_dragover)
        @element.addEventListener("dragleave", @on_dragleave)
        @element.addEventListener("drop", @on_drop)
        # prevent the whole list is dragged.
        @element.addEventListener("dragstart", (e)->e.preventDefault())
        @element.draggable = true
        @insert_indicator = create_element(tag:"div", class:"InsertIndicator")
        @insert_indicator.addEventListener("webkitTransitionEnd", (e)=>
            panel.cancelAnimation()
            console.log("transition end")
            update_dock_region()
            if @is_insert_indicator_shown
                return
            console.log("remove child from app list")
            @element.removeChild(@insert_indicator)
        )
        @_insert_anchor_item = null
        @is_insert_indicator_shown = false

    append: (c)->
        if @_insert_anchor_item and @_insert_anchor_item.element.parentNode == @element
            @element.insertBefore(c.element, @_insert_anchor_item.element)
            @_insert_anchor_item = null
        else
            @append_app_item(c)
        run_post(calc_app_item_size)

    append_app_item: (c)->
        @element.appendChild(c.element)

    record_last_over_item: (item)->
        @_insert_anchor_item = item

    on_drop: (e)=>
        e.stopPropagation()
        e.preventDefault()
        console.log("do drop on app_list")
        _lastHover?.reset()
        dt = e.dataTransfer
        if dnd_is_desktop(e)
            console.log("is desktop")
            path = dt.getData("text/uri-list").substring("file://".length).trim()
            id = get_path_name(path)
            t = create_element(tag:'div', name:id)
            # console.log("insert tmp before insert_indicator")
            if @insert_indicator
                @element.insertBefore(t, @insert_indicator)
            else
                @element.appendChild(t)
            dockedAppManager?.Dock(id, "", "", "")
        else if dnd_is_deepin_item(e)# and @insert_indicator.parentNode == @element
            id = dt.getData(DEEPIN_ITEM_ID)
            item = Widget.look_up(id) or Widget.look_up("le_"+id)
            if @insert_indicator
                @element.insertBefore(item.element, @insert_indicator)
            else
                @element.appendChild(item.element)
            sortDockedItem()
            # @append(item)
        # calc_app_item_size()
        updatePanel()

    on_dragover: (e) =>
        # console.log("start applist dragover")
        clearTimeout(cancelInsertTimer)
        e.preventDefault()
        e.stopPropagation()
        return
        dt = e.dataTransfer
        if dnd_is_deepin_item(e) or dnd_is_desktop(e)
            if e.y < screen.height - DOCK_HEIGHT + ITEM_HEIGHT / 4
                return

            console.log("effective dragover on applist")
            clearTimeout(showIndicatorTimer)
            try_insert_id = dt.getData(DEEPIN_ITEM_ID)

            dt.dropEffect = "copy"
            step = 6
            x = e.x
            y = e.y
            if e.y > screen.height - DOCK_HEIGHT + ITEM_HEIGHT
                y -= ITEM_HEIGHT / 2

            el = null
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
                    break
            el = el.parentNode.parentNode.parentNode if el
            if el.parentNode.id != "app_list"
                el = null
            return
            # console.log("get element")
            # console.log(el)
            # if el == null or el.id != try_insert_id
            #     console.log(el)
            #     clearTimeout(showIndicatorTimer || null)
            #     # to avoid insert to indicator
            #     # FIXME: why???
            #     showIndicatorTimer = setTimeout(=>
            #         console.log("show indicator")
            #         # @show_indicator(el, try_insert_id)
            #     , 10)

    on_dragleave: (e)=>
        clearTimeout(showIndicatorTimer)
        console.log("app_list dragleave")
        e.stopPropagation()
        e.preventDefault()

    on_dragenter: (e)=>
        console.log("applist dragenter")
        e.stopPropagation()
        e.preventDefault()
        DCore.Dock.require_all_region()
        # @on_dragover(e)

    swap_item: (src, dest)->
        swap_element(src.element, dest.element)
        items = []
        appList = $("#app_list")
        for i in [0...appList.children.length]
            child = appList.children[i]
            items.push(child.id)
        dockedAppManager.Sort(items)


app_list = new AppList("app_list")
