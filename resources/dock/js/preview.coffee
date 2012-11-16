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

    push: (child) ->
        @element.appendChild(child.element)
    pop: (pw) ->

    close_all: ->
        @current_group = null
        @current_shows?.forEach((c)-> c.destroy())
        DCore.Dock.close_show_temp()

    update: ->
        for pw in @current_shows
            pw.update_content()

    show_group: (group, offset)->
        if @current_group == group
            return
        else if @current_group != null
            echo "show_group2"
            @current_shows?.forEach((c)-> c.destroy())

        @current_group = group
        @current_shows = []
        group.clients.forEach( (c)=>
            pw = new PreviewWindow(c.pw_id, c.id, c.title, 200, 100)
            @current_shows.push(pw)
        )

        if @element.clientWidth == screen.width
            @element.style.left = 0
            DCore.Dock.show_temp_region(0, @element.offsetTop, @element.clientWidth, @element.clientHeight)
        else
            @element.style.left = offset + "px"
            DCore.Dock.show_temp_region(offset, @element.offsetTop, @element.clientWidth, @element.clientHeight)
        @update()


preview_container = new PWContainer("pwcontainer")

class PreviewWindow extends Widget
    constructor: (@id, @w_id, @title, @width, @height)->
        super
        @element.innerHTML = "
        <canvas id=c#{@id} width=#{@width}px height=#{@height}px></canvas>
        <div class=PWTitle>#{@title}</div>
        <div class=PWClose>X</div>
        "
        preview_container.push(@)

        @ctx = $("#c#{@id}").getContext('2d')

    do_click: (e)->
        DCore.Dock.set_active_window(@w_id)

    update_content: ->
        s = DCore.Dock.fetch_window_preview(@w_id, 200, 100)
        #img = @ctx.getImageData(0, 0, s.width, s.height)
        #for v,i in s.data
            #img.data[i] = v
        #@ctx.putImageData(img, 0, 0)

DCore.signal_connect("leave-notify", preview_container.close_all)
