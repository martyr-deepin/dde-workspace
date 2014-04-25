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
        @panel.width = 0
        @panel.height = PANEL_HEIGHT
        # @panel.addEventListener("resize", @redraw)

        @panel.addEventListener("click", @on_click)
        $("#containerWarp").addEventListener("click", @on_click)

        @globalMenu = new GlobalMenu()
        @panel.addEventListener("contextmenu", @on_rightclick)
        $("#containerWarp").addEventListener("contextmenu", @on_rightclick)

        @has_notifications = false

    inPanelWorkarea: (x, y)=>
        margin = (screen.width - @panel.width) / 2
        x >= margin && x <= screen.width - margin

    on_click: (e)=>
        e.stopPropagation()
        e.preventDefault()
        if @inPanelWorkarea(e.clientX, e.clientY)
            show_desktop.toggle()
            calc_app_item_size()
            Preview_close_now(_lastCliengGroup)

    on_rightclick: (e)=>
        e.preventDefault()
        e.stopPropagation()
        if @inPanelWorkarea(e.clientX, e.clientY)
            @globalMenu.showMenu(e.clientX, e.clientY)

    load_image: (src)->
        img = new Image()
        img.src = src
        img

    redraw: =>
        # console.log("panel redraw")
        @draw()

    draw: =>
        DCore.Dock.draw_panel(
            @panel,
            PANEL_LEFT_IMAGE,
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
        echo "#{appid}, #{itemid}"
        if appid == DEEPIN_APPTRAY
            echo "show message"
            @has_notifications = true
            @redraw()
        else
            echo "not dapptray: #{itemid}"
            if itemid != "" && (w = Widget.look_up("le_#{itemid}"))?
                w.notify()
            else
                Widget.look_up("le_#{appid}")?.notify()

    updateWithAnimation:=>
        calc_app_item_size()
        DCore.Dock.require_all_region()
        @cancelAnimation()
        @calcTimer = webkitRequestAnimationFrame(@updateWithAnimation)

    cancelAnimation:=>
        webkitCancelAnimationFrame(@calcTimer || null)
