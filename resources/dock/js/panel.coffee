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
        @panel.width = ITEM_WIDTH * 3
        @panel.height = PANEL_HEIGHT
        # @panel.addEventListener("resize", @redraw)

        @panel.addEventListener("click", @on_click)
        $("#containerWarp").addEventListener("click", @on_click)

        @globalMenu = new GlobalMenu()
        @panel.addEventListener("contextmenu", @on_rightclick)
        $("#containerWarp").addEventListener("contextmenu", @on_rightclick)

        @has_notifications = false

    inEffectivePanelWorkarea: (x, y)=>
        if settings.displayMode() == DisplayMode.Classic
            true
        else
            margin = (screen.width - @panel.width) / 2
            itemMargin = (screen.width - $("#container").clientWidth) / 2
            # console.log("clickPointer: (#{x}, #{y}),\nx: [#{margin}, #{itemMargin}), (#{screen.width - itemMargin}, #{screen.width - margin}]\ny:#{screen.height - DOCK_HEIGHT + ITEM_HEIGHT}")
            y > screen.height - DOCK_HEIGHT + ICON_HEIGHT || (x >= margin && x < itemMargin || x > screen.width - itemMargin && x <= screen.width - margin)

    on_click: (e)=>
        e.stopPropagation()
        e.preventDefault()

        if settings.displayMode() == DisplayMode.Classic
            return

        if @inEffectivePanelWorkarea(e.clientX, e.clientY)
            show_desktop.toggle()
            calc_app_item_size()
            update_dock_region()
            Preview_close_now(_lastCliengGroup)

    on_rightclick: (e)=>
        e.preventDefault()
        e.stopPropagation()
        if @inEffectivePanelWorkarea(e.clientX, e.clientY)
            @globalMenu.showMenu(e.clientX, e.clientY)
            Preview_close_now()
            $tooltip?.hide()

    load_image: (src)->
        img = new Image()
        img.src = src
        img

    redraw: =>
        # console.log("panel redraw")
        @draw()

    draw: =>
        if settings.displayMode() == DisplayMode.Classic
            # @set_width(screen.width)
            # @panel.height(48)
            ctx = @panel.getContext('2d')
            ctx.clearRect(0, 0, @panel.width, @panel.height)
            ctx.rect(0, 0, @panel.width, @panel.height)
            ctx.fillStyle = 'rgba(0,0,0,.8)'
            ctx.fill()

            y = 0
            blackLineHeight = 1
            drawLine(ctx, 0, y, @panel.width, y, lineColor: 'rgba(0,0,0,.6)', lineWidth: blackLineHeight)

            y = blackLineHeight
            whiteLineHeight = 1
            drawLine(ctx, 0, y, @panel.width, y, lineColor: 'rgba(255,255,255,.15)', lineWidth: whiteLineHeight)
        else
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
        # console.warn("panel update with animation")
        @cancelAnimation()
        update_dock_region($("#container").clientWidth)
        panel.set_width(Panel.getPanelMiddleWidth())
        @calcTimer = webkitRequestAnimationFrame(@updateWithAnimation)

    cancelAnimation:=>
        webkitCancelAnimationFrame(@calcTimer || null)
        update_dock_region($("#container").clientWidth)

    # TODO: remove it.
    @getPanelMiddleWidth:->
        if settings.displayMode() == DisplayMode.Classic
            return screen.width
        else
            apps = $s(".AppItem")
            panel_width = ITEM_WIDTH * apps.length
            return panel_width

    @getPanelWidth:->
        @getPanelMiddleWidth() + PANEL_MARGIN * 2
