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


class PWContainer extends Widget
    _need_move_animation: false
    _cancel_move_animation_id: -1
    constructor: (@id)->
        super
        @border = create_element("div", "PWBorder", document.body)
        @element.style.maxWidth = screen.width - 30
        @border.appendChild(@element)
        @is_showing = false
        @_current_group = null
        @_update_id = -1
        @arrow = new Arrow("PreviewArrow")
        @border.appendChild(@arrow.element)
        @_current_pws = {}

    hide: ->
        @is_showing = false
        @border.style.opacity = 0
    show: ->
        PWContainer._need_move_animation = true
        @is_showing = true
        @border.style.opacity = 1
        @border.style.display = "block"

    _update: ->
        clearInterval(@_update_id)
        setTimeout(=>
            @_update_once()
            @_calc_size()
            @show()
        , 5)
        @_update_id = setInterval(=>
            @_update_once()
        , 500)

    _update_once: ->
        for k, v of @_current_pws
            @_current_pws[k] = true

        @_current_group?.n_clients?.forEach((w_id)=>
            pw = Widget.look_up("pw"+w_id)
            if not pw
                info = @_current_group.client_infos[w_id]
                pw = new PreviewWindow("pw"+info.id, info.id, info.title)

            setTimeout(->
                pw.update_content()
            , 10)
            @_current_pws[w_id] = false
        )

        for k, v of @_current_pws
            if v == true
                Widget.look_up("pw"+k)?.destroy()

    _calc_size: ->
        return if @_current_group == null
        n = @_current_group.n_clients.length
        pw_width = clamp(screen.width / n, 0, PREVIEW_WINDOW_WIDTH)
        new_scale = pw_width / PREVIEW_WINDOW_WIDTH
        @scale = new_scale

        group_element = @_current_group.element
        x = get_page_xy(group_element, 0, 0).x + group_element.clientWidth / 2
        @x = x

        center_position = x - (pw_width * n / 2)
        offset = clamp(center_position, 5, screen.width - @pw* n)
        @arrow.move_to(x.toFixed() - offset - 3) # 3 is the half length of arrow width

        if @element.clientWidth == screen.width
            @border.style.left = 0
        else
            @border.style.left = offset

        if PWContainer._need_move_animation
            @border.style.display = "block"
        else
            @border.style.display = "none"

        DCore.Dock.require_all_region()

    append: (pw)->
        @_current_pws[pw.w_id] = true
        @element.appendChild(pw.element)

    remove: (pw)->
        assert(not Widget.look_up(pw.id))
        delete @_current_pws[pw.w_id]
        @close() if Object.keys(@_current_pws).length == 0


    close: ->
        clearInterval(@_update_id)
        @_current_group = null
        Object.keys(@_current_pws).forEach((w_id)->
            Widget.look_up("pw"+w_id)?.destroy()
        )
        update_dock_region()
        @is_showing = false
        #DCore.Dock.set_compiz_workaround_preview(false)

    show_group: (group)->
        clearTimeout(PWContainer._cancel_move_animation_id)
        PWContainer._cancel_move_animation_id = -1
        #DCore.Dock.set_compiz_workaround_preview(true)
        return if @_current_group == group
        @hide()
        @_current_group = group
        @_update()

    do_mouseover: ->
        clearTimeout(hide_id)
        DCore.Dock.require_all_region()
        __clear_timeout()



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

Preview_close_now = ->
    __clear_timeout()
    return if Preview_container.is_showing == false
    Preview_container.hide()
    setTimeout(->
        Preview_container.close()
        PWContainer._cancel_move_animation_id = setTimeout(->
            PWContainer._need_move_animation = false
        , 3000)
    , 300)
    # timeout above + timeout of backend = 400ms
    # to avoid the fact that dock doesn't hide, delay 500ms
    setTimeout(->
        DCore.Dock.update_hide_mode()
    , 500)
Preview_close = ->
    __clear_timeout()
    if Preview_container.is_showing
        __CLOSE_PREVIEW_ID = setTimeout(->
            Preview_close_now()
        , 500)

_current_active_pw_window = null
Preview_active_window_changed = (w_id) ->
    _current_active_pw_window?.to_normal()
    _current_active_pw_window = Widget.look_up("pw#{w_id}")
    _current_active_pw_window?.to_active()

class PreviewWindow extends Widget
    constructor: (@id, @w_id, @title_str)->
        super
        @title = create_element("div", "PWTitle", @element)
        @title.setAttribute("title", @title_str)
        @title.innerText = @title_str

        @canvas_container = create_element("div", "PWCanvas", @element)
        @canvas = create_element("canvas", "", @canvas_container)

        @update_size()

        @close_button = create_element("div", "PWClose", @canvas_container)
        @close_button.addEventListener('click', (e)=>
            e.stopPropagation()
            DCore.Dock.close_window(@w_id)
        )

        if get_active_window() == @w_id
            @to_active()
        else
            @to_normal()

        Preview_container.append(@)
        Preview_container._calc_size()

    delay_destroy: ->
        setTimeout(=>
            @destroy()
        , 100)

    destroy: ->
        super
        Preview_container.remove(@)
        Preview_container._calc_size()

    update_size: ->
        @scale = Preview_container.scale
        @element.style.width = PREVIEW_WINDOW_WIDTH * @scale
        @element.style.height = PREVIEW_WINDOW_HEIGHT * @scale
        @canvas_width = PREVIEW_CANVAS_WIDTH * @scale
        @canvas_height = PREVIEW_CANVAS_HEIGHT * @scale
        @canvas.setAttribute("width", @canvas_width)
        @canvas.setAttribute("height", @canvas_height)
        @canvas_container.style.width = @canvas_width
        @canvas_container.style.height = @canvas_height

    to_active: ->
        _current_active_pw_window = @
        @add_css_class("PreviewWindowActived")
    to_normal: ->
        @remove_css_class("PreviewWindowActived")

    do_click: (e)->
        DCore.Dock.active_window(@w_id)
        Preview_close_now()
    do_rightclick: (e)=>
        DCore.Dock.active_window(@w_id)
    do_mouseover: (e)=>
        Preview_active_window_changed(@w_id)

    update_content: ->
        if @scale != Preview_container.scale
            @update_size()
        DCore.Dock.draw_window_preview(@canvas, @w_id, @canvas_width, @canvas_height)


DCore.signal_connect("leave-notify", ->
    Preview_close()
)

document.body.addEventListener("click", (e)->
    return if e.target.classList.contains("PWClose") or e.target.classList.contains("PreviewWindow")
    Preview_close_now()
)
document.body.addEventListener("contextmenu", (e)->
    return if e.target.classList.contains("PWClose") or e.target.classList.contains("PreviewWindow")
    Preview_close_now()
)

document.body.addEventListener("mouseover", (e)->
    if (e.target == document.body)
        Preview_close()
)
