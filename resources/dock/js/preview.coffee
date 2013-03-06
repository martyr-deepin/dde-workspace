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

#TODO: dynamicly create/destroy PrewviewWindow when Client added/removed and current PreviewContainer is showing.
class Arrow extends Widget
    constructor: (@id)->
        super
        arrow_outter = create_element("div", "pop_arrow_up_outer", @element)
        arrow_mid = create_element("div", "pop_arrow_up_mid", @element)
        arrow_inner = create_element("div", "pop_arrow_up_inner", @element)
    move_to: (left)->
        @element.style.left = left + "px"
        @show()
    show: ->
        @element.style.display = "block"
    hide: ->
        @element.style.display = "none"


class PWContainer extends Widget
    constructor: (@id)->
        super
        @border = create_element("div", "PWBorder", document.body)
        @border.appendChild(@element)
        @is_showing = false
        @_current_group = null
        @_update_id = -1
        @arrow = new Arrow("PreviewArrow")
        @arrow.hide()
        @border.appendChild(@arrow.element)

    append: (el)->
        @element.appendChild(el)
        @_calc_size()

    _update: ->
        @is_showing = true
        clearInterval(@_update_id)
        for pw in @element.children
            Widget.look_up(pw.id)?.update_content()
        @_update_id = setInterval(=>
            for pw in @element.children
                Widget.look_up(pw.id)?.update_content()
        , 200)

    _calc_size: ->
        n = @_current_group.n_clients.length
        @child_width = clamp(screen.width / n, 0, 230)
        @child_height = @child_width / 2
        center_position = get_page_xy(@_current_group.element, 0, 0).x - (@child_width*n - @_current_group.element.clientWidth) / 2
        @arrow.move_to(get_page_xy(@_current_group.element, 0, 0).x - get_page_xy(@element, 0, 0).x + @_current_group.element.clientWidth / 2)
        offset = clamp(center_position, 0, screen.width - @child_width * n)

        if @element.clientWidth == screen.width
            @border.style.left = 0
            DCore.Dock.require_region(0, -@element.clientHeight, @element.clientWidth + 20, @element.clientHeight + 20)
        else
            @border.style.left = offset + "px"
            DCore.Dock.require_region(offset, -@element.clientHeight-10, @element.clientWidth + 20, @element.clientHeight + 20)


    remove_all: ->
        @arrow.hide()
        DCore.Dock.release_region(0, -@element.clientHeight, screen.width, @element.clientHeight)
        clearInterval(@_update_id)
        tmp = []
        for i in $s(".PreviewWindow")
            tmp.push(Widget.look_up(i.id))
        tmp.forEach( (pw)->
            pw?.destroy()
        )
        @_update_id = -1
        @_current_group = null
        @is_showing = false


    show_group: (group)->
        return if @_current_group == group
        @remove_all()
        @_current_group = group
        group.n_clients.forEach( (id)=>
            info = group.client_infos[id]
            if not Widget.look_up("pw"+id)
                pw = new PreviewWindow("pw"+id, id, info.title, 200, 100)
                @append(pw.element)
        )
        @_calc_size()
        @_update()

    do_mouseover: ->
        __clear_timeout()

    remove: (pw)->
        # used by other
        @arrow.hide()
        pw?.destroy
        @_calc_size()


Preview_container = new PWContainer("pwcontainer")

__SHOW_PREVIEW_ID = -1
__CLOSE_PREVIEW_ID = -1
__clear_timeout = ->
    clearTimeout(__SHOW_PREVIEW_ID)
    clearTimeout(__CLOSE_PREVIEW_ID)
    __SHOW_PREVIEW_ID = -1
    __CLOSE_PREVIEW_ID = -1

Preview_show = (group) ->
    __clear_timeout()
    if Preview_container.is_showing
        Preview_container.show_group(group)
    else
        __SHOW_PREVIEW_ID = setTimeout(->
            Preview_container.show_group(group)
        , 1000)

Preview_close = ->
    __clear_timeout()
    if Preview_container.is_showing
        __CLOSE_PREVIEW_ID = setTimeout(->
            Preview_container.remove_all()
        , 1000)
Preview_close_now = ->
    __clear_timeout()
    Preview_container.remove_all()

_current_active_pw_window = null
Preview_active_window_changed = (w_id) ->
    _current_active_pw_window?.to_normal()
    _current_active_pw_window = Widget.look_up("pw#{w_id}")
    _current_active_pw_window?.to_active()

class PreviewWindow extends Widget
    constructor: (@id, @w_id, @title_str, @width, @height)->
        super

        @title = create_element("div", "PWTitle", @element)
        @title.setAttribute("title", @title_str)
        @title.innerText = @title_str

        @canvas = create_element("canvas", "PWCanvas", @element)
        @canvas.setAttribute("width", 190)
        @canvas.setAttribute("height", 110)


        @close_button = create_element("div", "PWClose", @element)
        @close_button.addEventListener('click', (e)=>
            DCore.Dock.close_window(@w_id)
            e.stopPropagation()
            @destroy()
        )

        if get_active_window() == @w_id
            @to_active()
        else
            @to_normal()
    to_active: ->
        @close_button.style.display = "block"
        @add_css_class("PreviewWindowActived")
    to_normal: ->
        @close_button.style.display = "none"
        @remove_css_class("PreviewWindowActived")

    do_mouseover: (e)->
        DCore.Dock.active_window(@w_id)
    do_click: (e)->
        Preview_close_now()

    update_content: ->
        DCore.Dock.draw_window_preview(@canvas, @w_id, 200, 100)


DCore.signal_connect("leave-notify", ->
    Preview_close()
)
