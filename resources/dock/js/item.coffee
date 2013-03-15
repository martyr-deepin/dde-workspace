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
    else
        echo "can't find last app #{apps.length}"

document.body.onresize = ->
    calc_app_item_size()

class AppList extends Widget
    constructor: (@id) ->
        super
        $("#container").insertBefore(@element, $("#notifyarea"))

    append: (c) ->
        @element.appendChild(c.element)
        run_post(calc_app_item_size)

    do_drop: (e)->
        file = e.dataTransfer.getData("text/uri-list").substring(7)
        if file.length > 9  # strlen("x.desktop") == 9
            DCore.Dock.request_dock(decodeURI(file.trim()))

    do_dragover: (e) ->
        e.dataTransfer.dropEffect="link"

    do_mouseover: (e)->
        if e.target == @element
            Preview_close()

app_list = new AppList("app_list")

class AppItem extends Widget
    is_fixed_pos: false
    constructor: (@id, @icon)->
        super
        @add_css_class("AppItem")

        if not @icon
            @icon = NOT_FOUND_ICON
        @img = create_img("AppItemImg", @icon, @element)
        @img.classList.add("ReflectImg")
        @element.draggable=true
        app_list.append(@)

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

        if @indicate
            h = INDICATER_HEIGHT * ICON_SCALE
            @indicate.style.width = INDICATER_WIDTH * ICON_SCALE
            @indicate.style.height = h
            @indicate.style.top = ITEM_HEIGHT * ICON_SCALE - h

    do_dragstart: (e)->
        DCore.Dock.require_region(0, ITEM_HEIGHT - screen.height, screen.width, screen.height - ITEM_HEIGHT)
        Preview_close_now()
        return if @is_fixed_pos
        e.dataTransfer.setDragImage(@img, @img.clientWidth/2, @img.clientHeight/2)
        e.dataTransfer.setData("deepin-item-id", @element.id)
        e.dataTransfer.effectAllowed = "move"
        e.stopPropagation()
        @element.style.opacity = "0.5"

    do_dragend: (e)->
        setTimeout(=>
            DCore.Dock.release_region(0, ITEM_HEIGHT - screen.height, screen.width, screen.height - ITEM_HEIGHT)
        ,500)
        @element.style.opacity = "1"

    do_dragover: (e) ->
        e.preventDefault()
        return if @is_fixed_pos
        sid = e.dataTransfer.getData("deepin-item-id")
        if not sid
            return
        did = @element.id
        if sid != did
            w_s = Widget.look_up(sid)
            w_d = Widget.look_up(did)
            swap_element(w_s.element, w_d.element)
            if w_s.app_id
                id_s = w_s.app_id
            else
                id_s = w_s.id
            if w_d.app_id
                id_d = w_d.app_id
            else
                id_d = w_d.id
            DCore.Dock.swap_apps_position(id_s, id_d)

        e.stopPropagation()

    do_drop: (e) ->
        e.preventDefault()
        e.stopPropagation()
        if e.dataTransfer.getData("deepin-item-id")
            return
        tmp_list = []
        for file in e.dataTransfer.files
            path = decodeURI(file.path)
            entry = DCore.DEntry.create_by_path(path)
            tmp_list.push(entry)
        if tmp_list.length > 0
            switch this.constructor.name
                when "Launcher" then DCore.DEntry.launch(@core, tmp_list)
                when "ClientGroup" then DCore.Dock.launch_by_app_id(@app_id, tmp_list)


document.body.addEventListener("drop", (e)->
    s_id = e.dataTransfer.getData("deepin-item-id")
    s_widget = Widget.look_up(s_id)
    if s_widget and s_widget.constructor.name == "Launcher"
        s_widget.element.style.position = "fixed"
        s_widget.element.style.left = (e.x + s_widget.element.clientWidth/2)+ "px"
        s_widget.element.style.top = (e.y + s_widget.element.clientHeight/2)+ "px"
        s_widget.destroy_with_animation()
        setTimeout(=>
            DCore.Dock.request_undock(s_id)
        ,500)
)
document.body.addEventListener("dragover", (e)->
    s_id = e.dataTransfer.getData("deepin-item-id")
    if Widget.look_up(s_id)?.constructor.name == "Launcher"
        e.preventDefault()
)
