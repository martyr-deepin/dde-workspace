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
        @element.addEventListener('mouseover', ->
            resetAllItems()
        )
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
        @element.style.width = ''
        _dropped = true
        # FIXME: why drop event is triggered twice???
        e.stopPropagation()
        e.preventDefault()
        console.log("do drop on app_list")
        _lastHover?.reset()
        dt = e.dataTransfer
        DCore.Dock.set_is_hovered(false)
        update_dock_region()
        if dnd_is_desktop(e)
            # console.log("is desktop")
            path = dt.getData("text/uri-list").substring("file://".length).trim()
            id = get_path_name(path).replace("_", "-").toLowerCase()
            if not Widget.look_up(id)
                t = document.getElementsByName(id)
                if t.length == 0
                    t = create_element(tag:'div', class: 'AppItem', name:id)
                else
                    t = t[0]
                console.log("insert_anchor_item: #{@insert_anchor_item}")
                if @insert_anchor_item
                    @element.insertBefore(t, @insert_anchor_item)
                else
                    @element.appendChild(t)

                dockedAppManager?.Dock(id, "", "", "")
        else if dnd_is_deepin_item(e)# and @insert_indicator.parentNode == @element
            console.log("deepin item")
            id = dt.getData(DEEPIN_ITEM_ID)
            _dragTarget = _dragTargetManager.getHandle(id)
            _dragTarget?.dragToBack = false
            item = Widget.look_up(id)
            item?.element.style.display = ''
            if @insert_anchor_item
                console.log("insertBefore: #{@insert_anchor_item.id}")
                @element.insertBefore(item.element, @insert_anchor_item)
            else
                console.log("appendChild")
                @element.appendChild(item.element)
            sortDockedItem()

        updatePanel()
        update_dock_region()

    on_dragover: (e) =>
        # console.log("start applist dragover")
        e.preventDefault()
        e.stopPropagation()

    on_dragleave: (e)=>
        clearTimeout(showIndicatorTimer)
        console.log("app_list dragleave")
        update_dock_region()
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
