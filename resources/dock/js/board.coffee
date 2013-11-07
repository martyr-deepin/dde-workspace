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


class Board
    constructor: (@id)->
        @board = $("##{@id}")
        @board.width = screen.width
        @board.height = BOARD_HEIGHT
        @draw()

    draw: ->
        # echo 'draw board'
        ctx = @board.getContext("2d")
        ctx.save()

        # draw board
        ctx.beginPath()
        ctx.moveTo(10, 0)
        ctx.lineTo(@board.width - 10, 0)
        ctx.lineTo(@board.width, DOCK_HEIGHT)
        ctx.lineTo(0, DOCK_HEIGHT)
        ctx.closePath()
        ctx.fillStyle = 'rgba(0, 0, 0, 0.8)'
        ctx.fill()
        ctx.restore()

    set_width: (w)->
        @board.width = w

    set_height: (h)->
        @board.height = h

    set_size: (w, h)->
        @set_width(w)
        @set_height(h)

