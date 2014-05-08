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
        # @insert_indicator = create_element(tag:"div", id:'insert_indicator', class:"AppItem")
        # create_img(src:'', @insert_indicator)
        @insert_anchor_item = null
        @_insert_anchor_item = null
        @is_insert_indicator_shown = false

    # setInsertIndicator: (dataUrl)->
    #     console.log("setInsertIndicator")
    #     $("#insert_indicator").firstChild.src = dataUrl

    setInsertAnchor: (el)->
        @insert_anchor_item = el

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
            # console.log("is desktop")
            path = dt.getData("text/uri-list").substring("file://".length).trim()
            id = get_path_name(path)
            t = document.getElementsByName(id)
            # FIXME: why trigger twice drop event???
            if t.length == 0
                t = create_element(tag:'div', class: 'AppItem', name:id)
            else
                t = t[0]
            console.log("insert_indicator: #{@insert_indicator}")
            if @insert_indicator
                @element.insertBefore(t, @insert_indicator)
            else
                @element.appendChild(t)

            # # FIXME: why using @insert_indicator will insert two item???
            # @insert_indicator.setAttribute('name', id)
            # console.log(@insert_indicator)
            # if @insert_anchor_item
            #     @element.insertBefore(@insert_indicator, @insert_anchor_item)
            # else
            #     @element.appendChild(@insert_indicator)
            dockedAppManager?.Dock(id, "", "", "")
        else if dnd_is_deepin_item(e)# and @insert_indicator.parentNode == @element
            _dragToBack = false
            id = dt.getData(DEEPIN_ITEM_ID)
            item = Widget.look_up(id) or Widget.look_up("le_"+id)
            # img = item.img.cloneNode(true)
            # _b.appendChild(img)
            # x = 0
            # y = 0
            # img.style.webkitTransform = "translate(#{x}px, #{y}px)"
            # img.style.display = ''
            if @insert_anchor_item
                @element.insertBefore(item.element, @insert_anchor_item)
            else
                @element.appendChild(item.element)
            sortDockedItem()
        updatePanel()
        update_dock_region()

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
        # if dnd_is_deepin_item(e) or dnd_is_desktop(e)
        #     dataUrl = e.dataTransfer.getData("ItemIcon")
        #     console.log(dataUrl)
        #     @setInsertIndicator(dataUrl)

    swap_item: (src, dest)->
        swap_element(src.element, dest.element)
        items = []
        appList = $("#app_list")
        for i in [0...appList.children.length]
            child = appList.children[i]
            items.push(child.id)
        dockedAppManager.Sort(items)


app_list = new AppList("app_list")
