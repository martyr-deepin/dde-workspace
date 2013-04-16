#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#Maintainer:  snyh <snyh@snyh.org>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.


calc_app_item_size = ->
    return if IN_INIT
    apps = $s(".AppItem")
    return if apps.length = 0

    list = $("#app_list")
    w = clamp((list.clientWidth - 26) / list.children.length, 34, ITEM_WIDTH * MAX_SCALE)
    ICON_SCALE = clamp(w / ITEM_WIDTH, 0, MAX_SCALE)

    for i in apps
        Widget.look_up(i.id)?.update_scale()

        h = w * (ITEM_HEIGHT / ITEM_WIDTH)
        height = h * (ITEM_HEIGHT - BOARD_IMG_MARGIN_BOTTOM) / ITEM_HEIGHT + BOARD_IMG_MARGIN_BOTTOM * ICON_SCALE
        DCore.Dock.change_workarea_height(height)

    update_dock_region()

update_dock_region = ->
    apps = $s(".AppItem")
    last = apps[apps.length-1]
    if last and last.clientWidth != 0
        offset = ICON_SCALE * ITEM_WIDTH * apps.length
        DCore.Dock.force_set_region(0, 0, offset, DOCK_HEIGHT)

document.body.onresize = ->
    calc_app_item_size()

class AppList extends Widget
    constructor: (@id) ->
        super
        $("#container").insertBefore(@element, $("#notifyarea"))
        @insert_indicator = create_element("div", "InsertIndicator")
        @_insert_anchor_item = null

    append: (c)->
        if @_insert_anchor_item and @_insert_anchor_item.element.parentNode == @element
            @element.insertBefore(c.element, @_insert_anchor_item.element)
            DCore.Dock.insert_apps_position(c.app_id, @_insert_anchor_item.app_id)
            @_insert_anchor_item = null
            @hide_indicator()
        else
            @element.appendChild(c.element)
        run_post(calc_app_item_size)

    append2: (c)->
        try  #TODO: remove DEBUG CODE
            @append(c)
            DCore.Dock.insert_apps_position(c.app_id, null) if @_insert_anchor_item == null
        catch error
            alert "AppList append :#{error}"

    record_last_over_item: (item)->
        @_insert_anchor_item = item

    do_drop: (e)->
        e.stopPropagation()
        e.preventDefault()
        if dnd_is_desktop(e)
            path = e.dataTransfer.getData("text/uri-list").substring("file://".length).trim()
            DCore.Dock.request_dock(decodeURI(path))
        else if dnd_is_deepin_item(e) and @insert_indicator.parentNode == @element
            id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
            item = Widget.look_up(id) or Widget.look_up("le_"+id)
            item.flash(0.5)
            @append2(item)
        @hide_indicator()
        update_dock_region()

    do_dragover: (e) ->
        e.preventDefault()
        e.stopPropagation()
        if dnd_is_deepin_item(e) or dnd_is_desktop(e)
            e.dataTransfer.dropEffect="copy"
            n = e.x / (ITEM_WIDTH * ICON_SCALE)
            if n > 2  # skip the show_desktop and show launcher AppItem
                @show_indicator(e.x, e.dataTransfer.getData(DEEPIN_ITEM_ID))
            else
                @hide_indicator()

    do_dragleave: (e)->
        @hide_indicator()
        e.stopPropagation()
        e.preventDefault()
        if not dnd_is_deepin_item(e)
            update_dock_region()
    do_dragenter: (e)->
        DCore.Dock.require_all_region()
        e.stopPropagation()
        e.preventDefault()

    swap_item: (src, dest)->
        swap_element(src.element, dest.element)
        DCore.Dock.swap_apps_position(src.app_id, dest.app_id)

    do_mouseover: (e)->
        if e.target == @element
            Preview_close()

    hide_indicator: ->
        if @insert_indicator.parentNode == @element
            @element.removeChild(@insert_indicator)

    show_indicator: (x, try_insert_id)->
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

app_list = new AppList("app_list")

class ToolTip extends Widget
    tooltip: null
    @set_text: (widget, text) ->
        ToolTip.tooltip ?= $("#tooltip")
        ToolTip.tooltip.innerText = text
    @show: ->
        DCore.Dock.require_all_region()
        ToolTip.tooltip.style.display = "block"
    @hide: ->
        echo 'ToolTip hide'
        update_dock_region()
        ToolTip.tooltip.style.display = "none"
    @move_to: (x, y) ->
        ToolTip.tooltip.style.left = "#{x}px"
        ToolTip.tooltip.style.bottom = "#{y}px"

class AppItem extends Widget
    is_fixed_pos: false
    tooltip_show_id: -1
    next: ->
        el = @element.nextElementSibling
        if el and el.classList.contains("AppItem")
            return Widget.look_up(el.id)
        else
            return null
    prev: ->
        el = @element.previousElementSibling
        if el and el.classList.contains("AppItem")
            return Widget.look_up(el.id)
        else
            return null
    constructor: (@id, @icon)->
        super
        @add_css_class("AppItem")

        if not @icon
            @icon = NOT_FOUND_ICON
        @img = create_img("AppItemImg", @icon, @element)
        @img.classList.add("ReflectImg")
        @img.style.pointerEvents = "auto"
        @element.draggable=true
        if @constructor.name == "Launcher"
            @app_id = @id
        app_list.append(@)

    flash: (time)->
        apply_animation(@img, "flash", time or 1000)
    rotate: (time) ->
        apply_animation(@img, "rotateOut", time or 1000)

    destroy: ->
        super
        calc_app_item_size()

    update_scale: () ->
        @element.style.maxWidth = ITEM_WIDTH * ICON_SCALE
        $("#container").style.minHeight = ITEM_HEIGHT * ICON_SCALE

        icon_width = ICON_WIDTH * ICON_SCALE
        icon_height = ICON_HEIGHT * ICON_SCALE

        @_img_margin_top = ITEM_HEIGHT * ICON_SCALE- icon_height - BOARD_IMG_MARGIN_BOTTOM * ICON_SCALE

        @img.style.marginTop = @_img_margin_top
        @img.style.marginLeft = BOARD_IMG_MARGIN_LEFT
        @img.style.width = icon_width
        @img.style.height = icon_height

        if @img2
            @img2.style.width = icon_width
            @img2.style.height = icon_height
        if @img3
            @img3.style.width = icon_width
            @img3.style.height = icon_height

        if @open_indicator
            h = INDICATER_HEIGHT * ICON_SCALE
            @open_indicator.style.width = INDICATER_WIDTH * ICON_SCALE
            @open_indicator.style.height = h
            @open_indicator.style.top = ITEM_HEIGHT * ICON_SCALE - h

    do_dragover: (e)->
        e.stopPropagation()
        e.preventDefault()
        return if @is_fixed_pos or (not dnd_is_file(e) and not dnd_is_deepin_item(e))
        app_list.record_last_over_item(@)

    do_dragstart: (e)->
        e.stopPropagation()
        DCore.Dock.require_all_region()
        app_list.record_last_over_item(@)
        Preview_close_now()
        return if @is_fixed_pos
        e.dataTransfer.setDragImage(@img, 6, 4)
        e.dataTransfer.setData(DEEPIN_ITEM_ID, @app_id)
        e.dataTransfer.effectAllowed = "copyMove"

    do_dragend: (e)->
        #TODO: This event may not apparence if drag the item drop and quickly clik other application
        e.stopPropagation()
        e.preventDefault()
        update_dock_region()

    show_swap_indicator: ->
        @add_css_class("ItemSwapIndicator", @img)
    hide_swap_indicator: ->
        @remove_css_class("ItemSwapIndicator", @img)

    do_dragenter: (e)->
        e.preventDefault()
        e.stopPropagation()
        return if @is_fixed_pos
        app_list.hide_indicator()

        @_try_swaping_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
        if @_try_swaping_id == @app_id
            e.dataTransfer.dropEffect = "none"
            return
        else if dnd_is_deepin_item(e)
            e.dataTransfer.dropEffect="copy"
            @show_swap_indicator()
        else
            e.dataTransfer.dropEffect="move"

    do_dragleave: (e)->
        @hide_swap_indicator()
        @_try_swaping_id = null
        @hide_swap_indicator()
        e.preventDefault()
        e.stopPropagation()

    _do_launch: (list) =>
        run_successful = DCore.DEntry.launch(@core, list)
        if not run_successful
            is_delete = confirm(_("The item is invalid. Do you want to remove it from the dock bar?"))
            if is_delete
                DCore.Dock.request_undock(@id)
    do_drop: (e) ->
        e.preventDefault()
        e.stopPropagation()
        @hide_swap_indicator()
        if dnd_is_deepin_item(e)
            if @_try_swaping_id != @app_id
                w_s = Widget.look_up(@_try_swaping_id) or Widget.look_up("le_" + @_try_swaping_id)
                app_list.swap_item(w_s, @)
        else
            tmp_list = []
            for file in e.dataTransfer.files
                path = decodeURI(file.path)
                entry = DCore.DEntry.create_by_path(path)
                tmp_list.push(entry)
            if tmp_list.length > 0
                switch this.constructor.name
                    when "Launcher" then @_do_launch tmp_list
                    when "ClientGroup" then DCore.Dock.launch_by_app_id(@app_id, tmp_list)
    set_tooltip_text: (@text) ->
        ToolTip.set_text(@, @text)
    do_mouseover: (e) =>
        @set_tooltip_text(@text)
        AppItem.tooltip_show_id = setTimeout(=>
            ToolTip.show()
            @_move_tooltip()
        , 300)
    do_mouseout: (e) =>
        clearTimeout(AppItem.tooltip_show_id)
        AppItem.tooltip_show_id = -1
        ToolTip.hide()

    _move_tooltip: ->
        item_x = get_page_xy(@element, 0, 0).x
        offset = (@element.clientWidth - ToolTip.tooltip.clientWidth) / 2

        echo "tooltip client width: #{ToolTip.tooltip.clientWidth}"
        x = item_x + offset + 5  # 5 for subtle adapt
        ToolTip.move_to(x.toFixed(), @element.clientHeight)



document.body.addEventListener("drop", (e)->
    s_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
    s_widget = Widget.look_up(s_id)
    if s_widget and s_widget.constructor.name == "Launcher"
        s_widget.element.style.position = "fixed"
        s_widget.element.style.left = (e.x + s_widget.element.clientWidth/2)+ "px"
        s_widget.element.style.top = (e.y + s_widget.element.clientHeight/2)+ "px"
        DCore.Dock.request_undock(s_id)
        s_widget.destroy_with_animation()
)
document.body.addEventListener("dragover", (e)->
    s_id = e.dataTransfer.getData(DEEPIN_ITEM_ID)
    if Widget.look_up(s_id)?.constructor.name == "Launcher"
        e.preventDefault()
)
