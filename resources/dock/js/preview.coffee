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


class PWContainer extends Widget
    constructor: (@id)->
        super
        document.body.appendChild(@element)
        @current_group = null

        @update_id = -1
        @hide_id = null
        @show_id = null

    do_mouseover: ->
        clearTimeout(@hide_id)

    _update: ->
        for pw in @element.children
            Widget.look_up(pw.id)?.update_content()
        @update_id = setInterval(=>
            for pw in @element.children
                Widget.look_up(pw.id)?.update_content()
        , 500)

    remove_all: (timeout)->
        __remove_all = =>
            #DCore.Dock.release_region(0, -@element.clientHeight, screen.width, @element.clientHeight)
            for i in $s(".PreviewWindow")
                run_post(->
                    Widget.look_up(i.id)?.destroy()
                )
            clearInterval(@update_id)
            @update_id = -1
            @current_group = null

        clearTimeout(@show_id)
        if timeout?
            @hide_id = setTimeout(__remove_all, timeout)
        else
            __remove_all()


    show_group: (group)->
        _show_group_ = (group)=>
            clearTimeout(@hide_id)

            @current_group = group
            group.n_clients.forEach( (id)=>
                info = group.client_infos[id]
                if not Widget.look_up("pw"+id)
                    pw = new PreviewWindow("pw"+id, id, info.title, 200, 100)
                    @element.appendChild(pw.element)
            )

            if @element.clientWidth == screen.width
                @element.style.left = 0
                DCore.Dock.require_region(0, -@element.clientHeight, @element.clientWidth, @element.clientHeight)
            else
                run_post(=>
                    offset = group.element.offsetLeft - @element.clientWidth / 2 + group.element.clientWidth / 2
                    @element.style.left = clamp(offset, 0, screen.width/2) + "px"
                    echo "1 offset:#{offset} clamp:#{clamp(offset, 0, screen.width/2)}"
                , @)

                run_post(=>
                    offset = @element.offsetLeft
                    DCore.Dock.require_region(offset, -@element.clientHeight, @element.clientWidth, @element.clientHeight)
                    echo "2 offset:#{offset}"
                , @)
            @_update()

        if @current_group == null
            @show_id = setTimeout(=>
                _show_group_(group)
            , 1000)
        else if @current_group == group
            clearTimeout(@hide_id)
        else if @current_group != null
            @remove_all()
            _show_group_(group)


Preview_container = new PWContainer("pwcontainer")

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
        DCore.Dock.set_active_window(@w_id)

    update_content: ->
        DCore.Dock.draw_window_preview($("#c#{@id}"), @w_id, 200, 100)


DCore.signal_connect("leave-notify", ->
    Preview_container.remove_all(1000)
)
