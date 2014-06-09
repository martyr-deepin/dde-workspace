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



#TODO: dynamicly create/destroy PreviewWindow when Client added/removed and current PreviewContainer is showing.
class PWContainer extends Widget
    _need_move_animation: false
    _cancel_move_animation_id: -1
    constructor: (@id)->
        super
        @border = create_element("div", "PWBorder", _b)
        @bg = create_element(tag:'canvas', class:"bg", @border)
        @element.style.maxWidth = screen.width - 30
        @border.appendChild(@element)
        @element.addEventListener("mouseover", @on_mouseover)
        @element.addEventListener("mouseout", @on_mouseout)
        @is_showing = false
        @_current_group = null
        @_update_id = -1
        @_current_pws = {}
        @hide_border_id = null

    hide: ->
        @is_showing = false
        @border.style.opacity = 0
        @cancelHide()
        @hide_border_id = setTimeout(=>
            @border.style.display = 'none'
        , 500)

    cancelHide:->
        clearTimeout(@hide_border_id)

    show: ->
        @cancelHide()
        PWContainer._need_move_animation = true
        @is_showing = true
        @border.style.opacity = 1
        @border.style.display = "block"

    _update: (allocation=null, cb=null)->
        clearInterval(@_update_id)
        setTimeout(=>
            @_update_once(cb)
            @_calc_size(allocation)
            @show()
        , 5)
        @_update_id = setInterval(=>
            @_update_once()
        , 500)

    _update_once: (cb)=>
        # console.log("_update_once")
        for k, v of @_current_pws
            @_current_pws[k] = true

        @_current_group?.n_clients?.forEach((w_id)=>
            pw = Widget.look_up("pw"+w_id)
            if not pw
                id = @_current_group.id
                infos = @_current_group.client_infos
                # console.log("create PreviewWindow, #{id}##{infos[w_id].id}")
                pw = new PreviewWindow("pw"+w_id, w_id, infos[w_id].title, cb)

            setTimeout(->
                if cb
                    cb(pw.canvas)
                else
                    pw.update_content?()
            , 10)
            @_current_pws[w_id] = false
        )

        for k, v of @_current_pws
            if v == true
                Widget.look_up("pw"+k)?.destroy()

    drawPanel:(triX)->
        ctx = @bg.getContext('2d')
        ctx.clearRect(0, 0, @bg.width, @bg.height)
        ctx.save()

        ctx.shadowBlur = PREVIEW_SHADOW_BLUR
        ctx.shadowColor = 'black'
        ctx.shadowOffsetY = PREVIEW_CONTAINER_BORDER_WIDTH

        ctx.strokeStyle = 'rgba(255,255,255,0.4)'
        ctx.lineWidth = PREVIEW_CONTAINER_BORDER_WIDTH

        ctx.fillStyle = "rgba(0,0,0,0.75)"

        radius = PREVIEW_CORNER_RADIUS
        contentWidth = @bg.width - radius * 2 - ctx.lineWidth * 2 - ctx.shadowBlur * 2
        topY = radius + ctx.lineWidth
        bottomY = @bg.height - PREVIEW_TRIANGLE.height - ctx.lineWidth * 2 - ctx.shadowBlur
        leftX = radius + ctx.shadowBlur
        rightX = leftX + contentWidth

        arch =
            TopLeft:
                ox: leftX
                oy: topY
                radius: radius
                startAngle: Math.PI
                endAngle: Math.PI * 1.5
            TopRight:
                ox: rightX
                oy: topY
                radius: radius
                startAngle: Math.PI * 1.5
                endAngle: Math.PI * 2
            BottomRight:
                ox: rightX
                oy: bottomY
                radius: radius
                startAngle: 0
                endAngle: Math.PI * 0.5
            BottomLeft:
                ox: leftX
                oy: bottomY
                radius: radius
                startAngle: Math.PI * 0.5
                endAngle: Math.PI
        ctx.beginPath()
        ctx.moveTo(ctx.shadowBlur, topY)
        ctx.arc(arch['TopLeft'].ox, arch['TopLeft'].oy, arch['TopLeft'].radius,
                arch['TopLeft'].startAngle, arch['TopLeft'].endAngle)

        ctx.lineTo(rightX, topY - radius)

        ctx.arc(arch['TopRight'].ox, arch['TopRight'].oy, arch['TopRight'].radius,
                arch['TopRight'].startAngle, arch['TopRight'].endAngle)

        ctx.lineTo(rightX + radius, bottomY)

        ctx.arc(arch['BottomRight'].ox, arch['BottomRight'].oy, arch['BottomRight'].radius,
                arch['BottomRight'].startAngle, arch['BottomRight'].endAngle)

        # bottom line
        halfWidth = leftX + contentWidth / 2
        triOffset = 0
        if triX < halfWidth
            console.log("left overflow")
            triOffset = triX - halfWidth
        else if halfWidth + triX > screen.width
            console.log("right overflow")
            triOffset = (halfWidth + triX) - screen.width

        ctx.lineTo(halfWidth + triOffset + PREVIEW_TRIANGLE.width / 2,
                   bottomY + radius)

        # triangle
        ctx.lineTo(halfWidth + triOffset,
                   bottomY + radius + PREVIEW_TRIANGLE.height)

        ctx.lineTo(halfWidth + triOffset - PREVIEW_TRIANGLE.width / 2,
                   bottomY + radius)

        # bottom line
        ctx.lineTo(leftX, bottomY + radius)

        ctx.arc(arch['BottomLeft'].ox, arch['BottomLeft'].oy, arch['BottomLeft'].radius,
                arch['BottomLeft'].startAngle, arch['BottomLeft'].endAngle)

        ctx.lineTo(ctx.shadowBlur, topY)

        ctx.stroke()
        ctx.fill()

        ctx.restore()

    _calc_size: (allocation)=>
        # console.log("_calc_size")

        return if @_current_group == null

        # console.log("@_current_group != null")

        if PWContainer._need_move_animation
            # console.log 'need move animation'
            @border.classList.add('moveAnimation')
            @border.style.display = "block"
        else
            @border.classList.remove('moveAnimation')
            @border.style.display = "none"

        console.log("allocation: #{allocation}")

        @pw_width = 0
        @pw_height = 0
        @scale = -1
        if allocation
            # console.log 'use pw-width'
            @pw_width = allocation.width
            @pw_height = allocation.height || 0
            n = 1
        else
            # console.log 'calculate'
            n = @_current_group.n_clients.length
            @pw_width = clamp(screen.width / n, 0, PREVIEW_WINDOW_WIDTH)

            new_scale = @pw_width / PREVIEW_WINDOW_WIDTH
            # console.log "@pw_width: #{@pw_width}, new_scale: #{new_scale}"
            @scale = new_scale

        if allocation
            window_width = @pw_width + PREVIEW_CORNER_RADIUS * 2
            @bg.width = window_width * n + (PREVIEW_CONTAINER_BORDER_WIDTH + PREVIEW_SHADOW_BLUR) * 2
        else
            window_width = @pw_width + (PREVIEW_WINDOW_MARGIN + PREVIEW_WINDOW_BORDER_WIDTH) * 2
            @bg.width = window_width * n + (PREVIEW_CONTAINER_BORDER_WIDTH + PREVIEW_SHADOW_BLUR) * 2

        extraHeight = PREVIEW_TRIANGLE.height + PREVIEW_CONTAINER_BORDER_WIDTH * 3
        if allocation
            @bg.height = allocation.height + extraHeight + (PREVIEW_CORNER_RADIUS + PREVIEW_WINDOW_BORDER_WIDTH) * 2
        else
            @bg.height = PREVIEW_CONTAINER_HEIGHT * @scale + extraHeight

        console.log("canvas width: #{@bg.width}, height: #{@bg.height}")
        # the container must not contain the shadow and the border
        @border.style.width = @bg.width - (PREVIEW_SHADOW_BLUR + PREVIEW_CONTAINER_BORDER_WIDTH) * 2
        @border.style.height = @bg.height

        group_element = @_current_group.element
        x = get_page_xy(group_element, 0, 0).x + group_element.clientWidth / 2

        @drawPanel(x)

        halfWidth = window_width * n / 2
        offset = x - halfWidth
        if halfWidth > x
            console.log("_calc:: left overflow")
            offset = PREVIEW_SHADOW_BLUR
        else if halfWidth + x > screen.width
            console.log("_calc:: right overflow")
            offset -= (halfWidth + x - screen.width) + PREVIEW_SHADOW_BLUR
        else
            offset = clamp(offset, 5, screen.width - @pw_width)

        console.log("get offset: #{offset}")
        @border.style.webkitTransform = "translateX(#{offset}px)"

    append: (pw)->
        @_current_pws[pw.w_id] = true
        @element.appendChild(pw.element)

    remove: (pw)->
        assert(not Widget.look_up(pw.id))
        delete @_current_pws[pw.w_id]
        @close() if Object.keys(@_current_pws).length == 0


    close: ->
        # console.log("PWContainer::close")
        clearInterval(@_update_id)
        @_current_group = null
        Object.keys(@_current_pws).forEach((w_id)->
            Widget.look_up("pw"+w_id)?.destroy()
        )
        update_dock_region()
        @is_showing = false

    show_group: (group, allocation, cb)->
        # console.log("show_group")
        clearTimeout(PWContainer._cancel_move_animation_id)
        PWContainer._cancel_move_animation_id = -1
        return if @_current_group == group
        # console.log("different current_group")
        @hide()
        @_current_group = group
        # console.log(allocation)
        @_update(allocation, cb)

    on_mouseover: (e)=>
        console.log("preview window mouseover")
        __clear_timeout()
        clearTimeout(tooltip_hide_id)
        clearTimeout(hide_id)
        DCore.Dock.require_all_region()

    on_mouseout: =>
        Preview_close(Preview_container._current_group)



Preview_container = new PWContainer("pwcontainer")

__SHOW_PREVIEW_ID = -1
__CLOSE_PREVIEW_ID = -1
__clear_timeout = ->
    clearTimeout(__SHOW_PREVIEW_ID)
    clearTimeout(__CLOSE_PREVIEW_ID)
    __SHOW_PREVIEW_ID = -1
    __CLOSE_PREVIEW_ID = -1

Preview_show = (group, allocation, cb) ->
    __clear_timeout()
    __SHOW_PREVIEW_ID = setTimeout(->
        # console.log(allocation)
        # console.log("Preview_show: show group")
        Preview_container.show_group(group, allocation, cb)
    , 300)

Preview_close_now = (client)->
    __clear_timeout()
    # calc_app_item_size()
    # return
    _lastCliengGroup?.embedWindows?.hide?()
    return if Preview_container.is_showing == false
    console.log("Preview_close_now")
    Preview_container.hide()
    setTimeout(->
        Preview_container.close()
        PWContainer._need_move_animation = false
        DCore.Dock.set_is_hovered(false)
        update_dock_region()
    , 300)
    setTimeout(->
        update_dock_region()
        hideStatusManager.updateState()
    , 500)
Preview_close = ->
    __clear_timeout()
    if Preview_container.is_showing
        __CLOSE_PREVIEW_ID = setTimeout(->
            # console.log("Preview_close")
            Preview_close_now(Preview_container._current_group)
        , 500)

_current_active_pw_window = null
Preview_active_window_changed = (w_id) ->
    _current_active_pw_window?.to_normal()
    _current_active_pw_window = Widget.look_up("pw#{w_id}")
    _current_active_pw_window?.to_active()

class PreviewWindow extends Widget
    constructor: (@id, @w_id, @title_str, @applet)->
        super
        @innerBorder = create_element(tag:'div', class:'PreviewWindowInner', @element)
        container = @innerBorder

        if not @applet
            @canvas_container = create_element("div", "PWCanvas", container)
            @canvas = create_element("canvas", "", @canvas_container)
            @canvas.width = @canvas.height = 1

            @close_button = create_element("div", "PWClose", @canvas_container)
            @normalImg = create_img(src:"img/close_normal.png", @close_button)
            @hoverImg = create_img(src:"img/close_hover.png", @close_button)
            @hoverImg.style.display = 'none'
            @close_button.addEventListener('click', (e)=>
                e.stopPropagation()
                @canvas = null
                clearInterval(@_update_id)
                clientManager?.CloseWindow(@w_id)
            )
            @close_button.addEventListener("mouseover", (e)=>
                @hoverImg.style.display = 'inline'
                @normalImg.style.display = 'none'
            )
            @close_button.addEventListener("mouseout", (e)=>
                @hoverImg.style.display = 'none'
                @normalImg.style.display = 'inline'
            )

            @titleContainer = create_element(tag:"div", class:"PWTitleContainer", container)
            @title = create_element(tag:"div", class:"PWTitle", @titleContainer)
            @title.setAttribute("title", @title_str)
            @title.innerText = @title_str
            @update_size()

            if get_active_window() == @w_id
                @to_active()
            else
                @to_normal()

        Preview_container.append(@)
        if @applet
        else
            Preview_container._calc_size()

    delay_destroy: ->
        setTimeout(=>
            @destroy()
        , 100)

    destroy: ->
        super
        # console.log("PreviewWindow destroy")
        Preview_container.remove(@)
        Preview_container._calc_size()

    update_size: ->
        # console.log("PreviewWindow::update_size: #{Preview_container.scale}")
        if Preview_container.scale == -1
            console.log("scale == -1")
            @element.style.margin = "15px"
            @element.style.width = Preview_container.pw_width + PREVIEW_WINDOW_BORDER_WIDTH * 2
            @element.style.height = Preview_container.pw_height + PREVIEW_WINDOW_BORDER_WIDTH * 2
            @canvas_width = Preview_container.pw_width
            @canvas_height = Preview_container.pw_height
        else
            @scale = Preview_container.scale || 1
            @element.style.margin = "#{15*@scale}px"
            # console.log("PWWindow scale: #{@scale}")
            @element.style.width = PREVIEW_WINDOW_WIDTH * @scale
            @element.style.height = PREVIEW_WINDOW_HEIGHT * @scale
            @canvas_width = PREVIEW_CANVAS_WIDTH * @scale
            # console.log("canvas width: #{@canvas_width}")
            @canvas_height = PREVIEW_CANVAS_HEIGHT * @scale
        if not @applet
            @canvas.setAttribute("width", @canvas_width)
            @canvas.setAttribute("height", @canvas_height)
            @canvas_container.style.width = @canvas_width
            @canvas_container.style.height = @canvas_height
        if @applet
            console.log("set margin to #{PREVIEW_CORNER_RADIUS}")
            @element.style.margin = "#{PREVIEW_CORNER_RADIUS}px"
            @innerBorder.style.width = @canvas_width
            @innerBorder.style.height = @canvas_height
        @titleContainer?.style.width = @canvas_width - PREVIEW_WINDOW_BORDER_WIDTH * 2

    to_active: ->
        _current_active_pw_window = @
        @add_css_class("PreviewWindowActived")

    to_normal: ->
        @remove_css_class("PreviewWindowActived")

    do_click: (e)=>
        clientManager?.ActiveWindow(@w_id)
        Preview_close_now(Preview_container._current_group)

    do_rightclick: (e)=>
        clientManager?.ActiveWindow(@w_id)

    do_mouseover: (e)=>
        clearTimeout(normal_mouseout_id)
        if not @applet
            Preview_active_window_changed(@w_id)

    update_content: ->
        if @scale != Preview_container.scale
            @update_size()

        if @applet
            return

        if @w_id != 0
            # console.log("draw_window_preview: #{@canvas_width}, #{@canvas_height}")
            DCore.Dock.draw_window_preview(@canvas, @w_id, @canvas_width, @canvas_height)


DCore.signal_connect("leave-notify", ->
    Preview_close()
)

_b.addEventListener("click", (e)->
    return if e.target.classList.contains("PWClose") or e.target.classList.contains("PreviewWindow")
    Preview_close_now(Preview_container._current_group)
)
_b.addEventListener("contextmenu", (e)->
    return if e.target.classList.contains("PWClose") or e.target.classList.contains("PreviewWindow")
    Preview_close_now(Preview_container._current_group)
)

_b.addEventListener("mouseover", (e)->
    if (e.target == _b)
        Preview_close()
)
