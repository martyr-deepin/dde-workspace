#Copyright (c) 2011 ~ Deepin, Inc.
#              2011 ~ 2012 snyh
#              2013 ~ Liqiang Lee
#
#Author:      Liqiang Lee <liliqiang@linuxdeepin.com>
#Maintainer:  Liqiang Lee <liliqiang@linuxdeepin.com>
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


class Panel
    constructor: (@id)->
        @panel = $("##{@id}")
        @panel.width = screen.width - PANEL_MARGIN * 2
        @panel.height = PANEL_HEIGHT
        @panel.addEventListener('click', (e)=>
            if e.offsetX < PANEL_MARGIN
                # echo '[panel] toggle show desktop'
                show_desktop.toggle()
            else if e.offsetX > @panel.width - @right_image.width and @has_notifications
                @has_notifications = false
                @redraw()
                # echo '[panel] show message'
        )

        @show_desktop_image = @load_image(PANEL_SHOW_DESKTOP_IMAGE)
        @right_image = @load_image(PANEL_NORMAL_RIGHT_IMAGE)
        @notifications_image = @load_image(PANEL_NOTIFICATION_IMAGE)
        @middle_image = @load_image(PANEL_MIDDLE_IMAGE)
        @has_notifications = false

    load_image: (src)->
        img = new Image()
        img.src = src
        img

    redraw: =>
        @draw()

    draw: =>
        if !(@show_desktop_image and @middle_image and @right_image and @notifications_image)
            return

        # echo "draw panel"
        PANEL_RIGHT_IMAGE = PANEL_NORMAL_RIGHT_IMAGE
        if @has_notifications
            PANEL_RIGHT_IMAGE = PANEL_NOTIFICATION_IMAGE

        DCore.Dock.draw_panel(
            @panel,
            PANEL_SHOW_DESKTOP_IMAGE,
            PANEL_MIDDLE_IMAGE,
            PANEL_RIGHT_IMAGE,
            @panel.width,
            PANEL_MARGIN,
            PANEL_HEIGHT
        )
        DCore.Dock.update_guard_window_width(@panel.width)

    _set_width: (w)->
        @panel.width = Math.min(w + PANEL_MARGIN * 2, screen.width)

    _set_height: (h)->
        @panel.height = Math.min(h, screen.height)

    set_width: (w)->
        @_set_width(w)
        @redraw()

    set_height: (h)->
        @_set_height(h)
        @redraw()

    set_size: (w, h)->
        @_set_width(w)
        @_set_height(h)
        @redraw()

    width: ->
        @panel.width

    update: (appid, itemid)=>
        # echo "#{appid}, #{itemid}"
        if appid == DEEPIN_APPTRAY
            echo "show message"
            @has_notifications = true
            @redraw()
        else
            echo "not dapptray"
            try
                Widget.look_up(itemid)?.notify()
