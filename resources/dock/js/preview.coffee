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
        @current_shows = []

        @update_id = -1
        @hide_id = null
        @show_id = null

    do_mouseover: ->
        clearTimeout(@hide_id)

    do_mouseout: ->
        @remove_all(2500)

    add: (child) ->
        @element.appendChild(child.element)

        @current_shows.push(child)

    remove: (pw) ->
        if @current_shows.length == 1
            @remove_all()
        else
            @current_shows.remove(pw)
            pw?.destroy()

    remove_all: (timeout)->
        __remove_all = =>
            DCore.Dock.close_show_temp()
            clearInterval(@update_id)
            @update_id = -1
            @current_group = null
            for i in @current_shows
                i.destroy()
            @current_shows = []

        clearTimeout(@show_id)
        if @current_shows.length == 0
            __remove_all()
        else if timeout?
            @hide_id = setTimeout(__remove_all, timeout)
        else
            __remove_all()


    update: ->
        for pw in @current_shows
            pw.update_content()
        @update_id = setInterval(=>
            for pw in @current_shows
                pw.update_content()
        , 200)

    show_group: (group, offset)->
        _show_group_ = =>
            clearTimeout(@hide_id)

            @current_group = group
            group.clients.forEach( (c)=>
                pw = new PreviewWindow(c.pw_id, c.id, c.title, 200, 100)
            )

            if @element.clientWidth == screen.width
                @element.style.left = 0
                DCore.Dock.show_temp_region(0, @element.offsetTop, @element.clientWidth, @element.clientHeight)
            else
                @element.style.left = offset + "px"
                DCore.Dock.show_temp_region(offset, @element.offsetTop, @element.clientWidth, @element.clientHeight)
            @update()

        if @current_group == null or (@current_group == group and @update_id == -1)
            @show_id = setTimeout(=>
                _show_group_(group, offset)
            , 1000)
        else if @current_group != null
            @remove_all()
            _show_group_(group, offset)


Preview_container = new PWContainer("pwcontainer")

class PreviewWindow extends Widget
    constructor: (@id, @w_id, @title, @width, @height)->
        super
        @element.innerHTML = "
        <canvas class=PWCanvas id=c#{@id} width=#{@width}px height=#{@height}px></canvas>
        <div class=PWTitle title='#{@title}'>#{@title}</div>
        <div class=PWClose>X</div>
        "

        Preview_container.add(@)

        @canvas = $("#c#{@id}")

        $(@element, ".PWClose").addEventListener('click', (e)=>
            DCore.Dock.close_window(@w_id)
            e.stopPropagation()
        )

    do_click: (e)->
        DCore.Dock.set_active_window(@w_id)

    update_content: ->
        DCore.Dock.draw_window_preview(@canvas, @w_id, 200, 100)

DCore.signal_connect("leave-notify", ->
    Preview_container.remove_all(1000)
)
