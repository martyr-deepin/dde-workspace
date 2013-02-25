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
class PWContainer extends Widget
    constructor: (@id)->
        super
        document.body.appendChild(@element)
        @is_showing = false
        @_current_group = null
        @_update_id = -1

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
        offset = (screen.width - @child_width * n)/2
        x = get_page_xy(@_current_group.element, 0, 0).x - (@child_width * n - @_current_group.element.clientWidth) /2
        x = 0 if x < 0
        offset = clamp(offset, 0, x)

        if @element.clientWidth == screen.width
            @element.style.left = 0
            DCore.Dock.require_region(0, -@element.clientHeight, @element.clientWidth, @element.clientHeight)
        else
            @element.style.left = offset + "px"
            DCore.Dock.require_region(offset, -@element.clientHeight, @element.clientWidth, @element.clientHeight)


    remove_all: ->
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
        @remove_all()
        @_current_group = group
        group.n_clients.forEach( (id)=>
            info = group.client_infos[id]
            if not Widget.look_up("pw"+id)
                pw = new PreviewWindow("pw"+id, id, info.title, 200, 100)
                @element.appendChild(pw.element)
        )
        @_calc_size()
        @_update()

    do_mouseover: ->
        __clear_timeout()

    append: (pw)->
        # used by other
        @element.appendChild(pw.element)
        @_calc_size()

    remove: (pw)->
        # used by other
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


class PreviewWindow extends Widget
    constructor: (@id, @w_id, @title, @width, @height)->
        super

        @element.innerHTML = "
        <canvas class=PWCanvas id=c#{@id} width=#{@width}px height=#{@height}px></canvas>
        <div class=PWTitle title='#{@title}'>#{@title}</div>
        <div class=PWClose>X</div>
        "

        $(@element, ".PWClose").addEventListener('click', (e)=>
            DCore.Dock.close_window(@w_id)
            e.stopPropagation()
            @destroy()
        )

    do_click: (e)->
        DCore.Dock.active_window(@w_id)

    update_content: ->
        DCore.Dock.draw_window_preview($("#c#{@id}"), @w_id, 200, 100)


DCore.signal_connect("leave-notify", ->
    Preview_close()
)
