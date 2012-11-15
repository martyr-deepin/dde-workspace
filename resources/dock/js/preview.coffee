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

preview_current_id = 0
preview_show_delay_id = 0
_interval_id = 0
_hide_timeout_id = 0

class PWContainer extends Widget
    constructor: (@id)->
        super
        document.body.appendChild(@element)
        @curren_active = null

    push: (child) ->
        @element.appendChild(child.element)
    pop: (pw) ->

    close_all: ->
        @curren_active?.disactive()
        DCore.Dock.close_show_temp()

    active: (pw, offset) ->
        @curren_active?.disactive()
        @curren_active = pw
        pw.active(offset)
        DCore.Dock.show_temp_region(offset, 0, 300, 200)


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
        DCore.Dock.set_active_window(preview_current_id)

    do_mouseover: (e)->
        clearTimeout(_hide_timeout_id)

    do_mouseout: (e)->
        setTimeout(=>
            @disactive()
        ,1000)

    update_content: ->
        s = DCore.Dock.fetch_window_preview(@w_id, 300, 200)
        img = @ctx.getImageData(0, 0, s.width, s.height)
        for v,i in s.data
            img.data[i] = v
        @ctx.putImageData(img, 0, 0)

    clear_content: ->
        @ctx.clearRect(0, 0, @width, @height)

    active: (offset) ->
        @update_content()
        @element.style.left = offset + "px"

        #clearInterval(_interval_id)

        #preview_disactive(3000)
        #_interval_id = setInterval(_update_preview, 600)
        #DCore.Dock.show_temp_region(offset, 0, 300, 200)

    disactive: (timeout)->
        @destroy()
        #clearTimeout(_hide_timeout_id)
        #clearTimeout(preview_show_delay_id)
        #_hide_timeout_id = setTimeout(->
                        #clearInterval(_interval_id)
                        #_ctx.clearRect(0, 0, 300, 200)
                        #DCore.Dock.close_show_temp()
                        #preview_current_id = 0
                    #timeout)



preview_close_all = ->
    preview_container.close_all()

DCore.signal_connect("leave-notify", preview_close_all)
