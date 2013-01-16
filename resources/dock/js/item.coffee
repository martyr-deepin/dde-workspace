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
    apps = $s(".AppItem")
    if apps.length == 0
        return

    w = apps[0].offsetWidth
    last = apps[apps.length-1]
    if last and last.clientWidth != 0
        #TODO: the logic is mess.
        # when the last apps is in withdraw status, the clientWidth will be zero!
        #while last.clientWidth == 0
            #last = last.previousElementSibling
        DCore.Dock.require_region(0, 0, screen.width, DOCK_HEIGHT)
        p = get_page_xy(last, 0, 0)
        offset = p.x + last.clientWidth
        DCore.Dock.release_region(offset + ITEM_WIDTH, 0, screen.width - offset, 30)

        h = w * (ITEM_HEIGHT / ITEM_WIDTH)
        height = h * (ITEM_HEIGHT - BOARD_IMG_MARGIN_BOTTOM) / ITEM_HEIGHT + BOARD_IMG_MARGIN_BOTTOM
        DCore.Dock.change_workarea_height(height)
    else
        echo "can't find last app #{apps.length}"

    for i in apps
        Widget.look_up(i.id).change_size(w)

class AppList extends Widget
    constructor: (@id) ->
        super
        $("#container").insertBefore(@element, $("#notifyarea"))
        setTimeout(c, 200)

    append: (c) ->
        @element.appendChild(c.element)
        run_post(calc_app_item_size)

    do_drop: (e)->
        file = e.dataTransfer.getData("text/uri-list").substring(7)
        if file.length > 9  # strlen("x.desktop") == 9
            DCore.Dock.request_dock(decodeURI(file.trim()))

    show_try_dock_app: (e) ->
        path = e.dataTransfer.getData("text/uri-list").trim()
        t = path.substring(path.length-8)
        if t == ".desktop"
            lcg = $(".AppItem:last-of-type", @element)
            fcg = $(".AppItem:nth-of-type(3)", @element)
            lp = get_page_xy(lcg, lcg.clientWidth, 0)
            fp = get_page_xy(fcg, 0, 0)
            if e.pageX > lp.x
                x = lp.x
            else if e.pageX < fp.x
                x = fp.x
            else
                x = e.pageX

    do_dragover: (e) ->
        e.dataTransfer.dropEffect="link"
        @show_try_dock_app(e)

    do_mouseover: (e)->
        if e.target == @element
            Preview_container.remove_all(1000)

app_list = new AppList("app_list")

class AppItem extends Widget
    is_fixed_pos: false
    constructor: (@id, @icon)->
        super
        app_list.append(@)
        @add_css_class("AppItem")
        if not @icon
            @icon = NOT_FOUND_ICON
        @img = create_img("AppItemImg", @icon, @element)
        @element.draggable=true

    destroy: ->
        super
        calc_app_item_size()

    change_size: (item_width) ->
        icon_width = (ICON_HEIGHT / ITEM_WIDTH) * item_width
        icon_height = icon_width * (ICON_HEIGHT / ICON_WIDTH)

        @_img_margin_top = ITEM_HEIGHT - icon_height - BOARD_IMG_MARGIN_BOTTOM

        @img.style.marginTop = @_img_margin_top
        @img.style.marginLeft = BOARD_IMG_MARGIN_LEFT
        @img.style.width = icon_width
        @img.style.height = icon_height

        if @indicate
            w = INDICATER_WIDTH / ITEM_WIDTH * item_width
            h = w * INDICATER_HEIGHT / INDICATER_WIDTH
            @indicate.style.width = w
            @indicate.style.height = h
            @indicate.style.top = ITEM_HEIGHT - h

    do_dragstart: (e)->
        Preview_container.remove_all()
        return if @is_fixed_pos
        e.dataTransfer.setData("item-id", @element.id)
        e.dataTransfer.effectAllowed = "move"
        e.stopPropagation()
        @element.style.opacity = "0.5"

    do_dragend: (e)->
        @element.style.opacity = "1"

    do_dragover: (e) ->
        e.preventDefault()
        return if @is_fixed_pos
        sid = e.dataTransfer.getData("item-id")
        if not sid
            return
        did = @element.id
        if sid != did
            swap_element(Widget.look_up(sid).element, Widget.look_up(did).element)

        e.stopPropagation()

    do_drop: (e) ->
        e.preventDefault()
        e.stopPropagation()
        if e.dataTransfer.getData("item-id")
            return
        tmp_list = []
        for file in e.dataTransfer.files
            path = decodeURI(file.path)
            entry = DCore.DEntry.create_by_path(path)
            tmp_list.push(entry)
        switch this.constructor.name
            when "Launcher" then DCore.DEntry.launch(@core, tmp_list)
            when "ClientGroup" then DCore.Dock.launch_by_app_id(@app_id, tmp_list)
