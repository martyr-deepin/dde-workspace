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


class PanelImageInfo
    constructor: (@img, @x, @width)->
        @y = 0
        @height = PANEL_HEIGHT


class Panel
    constructor: (@id)->
        @panel = $("##{@id}")
        @panel.width = screen.width
        @panel.height = PANEL_HEIGHT
        @panel.addEventListener('click', (e)=>
            echo e.offsetX
            if e.offsetX < PANEL_MARGIN
                # echo '[panel] toggle show desktop'
                show_desktop.toggle()
            else if e.offsetX > @panel.width - @right_image.width
                echo '[panel] show message'
        )

        @show_desktop_image = new Image()
        @show_desktop_image.addEventListener("load", @draw)
        @show_desktop_image.src = PANEL_SHOW_DESKTOP_IMAGE

        @right_image = new Image()
        @right_image.addEventListener("load", @draw)
        @right_image.src = PANEL_RIGHT_IMAGE

        @notifications_image = new Image()
        @notifications_image.src = PANEL_NOTIFICATION_IMAGE

        @middle_image = new Image()
        @middle_image.addEventListener("load", @draw)
        @middle_image.src = PANEL_MIDDLE_IMAGE

        @side_width = 0

    draw: =>
        if !(@show_desktop_image and @middle_image and @right_image and @notifications_image)
            return

        # echo "draw panel"
        ctx = @panel.getContext("2d")
        ctx.save()
        ctx.shadowBlur = 20
        ctx.shadowColor = "rgba(0, 0, 0, .4)"
        left = new PanelImageInfo(@show_desktop_image, 0, @side_width)
        middle = new PanelImageInfo(@middle_image, @side_width, @panel.width - @side_width * 2)
        right = new PanelImageInfo(@right_image, @panel.width - @side_width, @side_width)
        if false
            right.img = @notifications_image
        OFFSET_Y = 0
        ctx.drawImage(left.img, left.x, OFFSET_Y, left.width, PANEL_HEIGHT)
        ctx.drawImage(middle.img, middle.x, OFFSET_Y, middle.width, PANEL_HEIGHT)
        ctx.drawImage(right.img, right.x, OFFSET_Y, right.width, PANEL_HEIGHT)
        ctx.restore()
        DCore.Dock.update_guard_window_width(@panel.width)

    _set_width: (w)->
        @panel.width = Math.min(w + @show_desktop_image.width + @right_image.width, screen.width)
        @side_width = (@panel.width - w) / 2

    _set_height: (h)->
        @panel.height = Math.min(h, screen.height)

    set_width: (w)->
        @_set_width(w)
        @draw()

    set_height: (h)->
        @_set_height(h)
        @draw()

    set_size: (w, h)->
        @_set_width(w)
        @_set_height(h)
        @draw()

    width: ->
        @panel.width
