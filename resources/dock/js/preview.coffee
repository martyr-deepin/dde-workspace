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
    constructor: (@id)->
        super
        @border = create_element("div", "PWBorder", _b)
        @bg = create_element(tag:'canvas', class:"bg", @border)
        @element.style.maxWidth = screen.width - 30
        @border.appendChild(@element)
        @callback = null
        @border.addEventListener("webkitTransitionEnd", =>
            @border.classList.remove("moveAnimation")
            @callback?()
        )
        @element.addEventListener("mouseover", @on_mouseover)
        @element.addEventListener("mouseout", @on_mouseout)
        @is_showing = false
        @_current_group = null
        @_update_id = -1
        @_current_pws = {}
        @hide_border_id = null
        @setAnimationDuration(400, null)

    setAnimationDuration: (duration, cb)->
        @border.classList.remove("moveAnimation")
        @border.classList.add("moveAnimation")
        @border.style.webkitTransitionDuration = "#{duration}ms"
        @callback= cb

    hide: ->
        @is_showing = false
        @border.style.display = 'none'

    show: ->
        @is_showing = true
        @border.style.opacity = 1
        @border.style.display = "block"
        PWContainer._need_move_animation = true

    _update: (allocation=null, cb=null)->
        clearInterval(@_update_id)
        setTimeout(=>
            @_update_once(cb)
            @_calc_size(allocation)
            @show()
        , 5)
        @_update_id = setInterval(=>
            if not @border.classList.contains("moveAnimation")
                @_update_once()
        , 60)

    _update_once: (cb)=>
        for k, v of @_current_pws
            @_current_pws[k] = true

        @_current_group?.n_clients?.forEach((w_id)=>
            pw = Widget.look_up("pw"+w_id)
            if not pw
                id = @_current_group.id
                infos = @_current_group.client_infos
                if infos[w_id]
                    pw = new PreviewWindow("pw"+w_id, w_id, infos[w_id].title, cb)

            setTimeout(->
                if !cb
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
        ctx.shadowColor = 'rgba(0,0,0,.5)'
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
            triOffset = triX - halfWidth
        else if halfWidth + triX > screen.width
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
        return if @_current_group == null

        if PWContainer._need_move_animation
            @border.classList.add('moveAnimation')
            @border.style.display = "block"
        else
            @border.classList.remove('moveAnimation')
            @border.style.display = "none"

        @pw_width = 0
        @pw_height = 0
        @scale = -1
        if allocation
            @pw_width = allocation.width
            @pw_height = allocation.height || 0
            n = 1
        else
            n = @_current_group.n_clients.length
            @pw_width = clamp(screen.width / n, 0, PREVIEW_WINDOW_WIDTH)

            new_scale = @pw_width / PREVIEW_WINDOW_WIDTH
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

        # the container must not contain the shadow and the border
        @border.style.width = @bg.width - (PREVIEW_SHADOW_BLUR + PREVIEW_CONTAINER_BORDER_WIDTH) * 2
        @border.style.height = @bg.height

        group_element = @_current_group.element
        x = get_page_xy(group_element, 0, 0).x + group_element.clientWidth / 2

        @drawPanel(x)

        halfWidth = window_width * n / 2
        offset = x - halfWidth
        if halfWidth > x
            offset = PREVIEW_SHADOW_BLUR
        else if halfWidth + x > screen.width
            offset -= (halfWidth + x - screen.width) + PREVIEW_SHADOW_BLUR
        else
            offset = clamp(offset, 5, screen.width - @pw_width)

        @border.style.webkitTransform = "translateX(#{offset}px)"

        bottom = PREVIEW_BOTTOM[settings.displayMode()]
        if @border.style.border != "#{bottom}px"
                @border.style.bottom = "#{bottom}px"

    append: (pw)->
        @_current_pws[pw.w_id] = true
        @element.appendChild(pw.element)

    remove: (pw)->
        assert(not Widget.look_up(pw.id))
        delete @_current_pws[pw.w_id]
        @close() if Object.keys(@_current_pws).length == 0


    close: ->
        @is_showing = false
        clearInterval(@_update_id)
        @_current_group = null
        # Object.keys(@_current_pws).forEach((w_id)->
        #     Widget.look_up("pw"+w_id)?.destroy()
        # )
        if debugRegion
            console.warn("[PWContainer.close] update_dock_region")
        update_dock_region()

    show_group: (group, allocation, cb)->
        return if @_current_group == group and Preview_container.is_showing
        @_current_group = group
        @_update(allocation, cb)

    on_mouseover: (e)=>
        __clear_timeout()
        clearTimeout(tooltip_hide_id)
        clearTimeout(hide_id)
        @is_showing = true
        DCore.Dock.require_all_region()

    on_mouseout: =>
        Preview_close(Preview_container._current_group)



Preview_container = new PWContainer("pwcontainer")

__SHOW_PREVIEW_ID = -1
__CLOSE_PREVIEW_ID = -1
_previewCloseTimer = null
_previewCloseUpdateStateTimer = null
__clear_timeout = ->
    clearTimeout(hide_id)
    hide_id = -1
    clearTimeout(closePreviewWindowTimer)
    closePreviewWindowTimer = -1
    clearTimeout(_previewCloseTimer)
    _previewCloseTimer = null
    clearTimeout(_previewCloseUpdateStateTimer)
    _previewCloseUpdateStateTimer = null
    clearTimeout(__SHOW_PREVIEW_ID)
    clearTimeout(__CLOSE_PREVIEW_ID)
    __SHOW_PREVIEW_ID = -1
    __CLOSE_PREVIEW_ID = -1

Preview_show = (group, allocation, cb) ->
    __clear_timeout()
    if cb and settings.displayMode() != DisplayMode.Fashion
        Preview_container.setAnimationDuration(200, cb)
        Preview_container.show_group(group, allocation, cb)
        if Preview_container.is_showing == false
            cb?()
    else
        Preview_container.setAnimationDuration(400, cb)
        __SHOW_PREVIEW_ID = setTimeout(->
            Preview_container.show_group(group, allocation, cb)
            if Preview_container.is_showing == false
                cb?()
        , 300)

Preview_close_now = (client)->
    __clear_timeout()
    # calc_app_item_size()
    # return
    _lastCliengGroup?.embedWindows?.hide?()
    for own xid, value of $EW_MAP
        $EW.hide(xid)
    return if Preview_container.is_showing == false
    _previewCloseTimer = setTimeout(->
        Preview_container.hide()
        Preview_container.close()
        PWContainer._need_move_animation = false
        if $tooltip
            if !$tooltip.isShown()
                DCore.Dock.set_is_hovered(false)
        else
            DCore.Dock.set_is_hovered(false)
        if debugRegion
            console.warn("[Preview_close_now.close_timer] update_dock_region")
        update_dock_region(Panel.getPanelMiddleWidth())
    , 10)
    _previewCloseUpdateStateTimer = setTimeout(->
        if debugRegion
            console.warn("[Preview_close_now.update_state_timer] update_dock_region")
        update_dock_region(Panel.getPanelMiddleWidth())
        hideStatusManager.updateState()
    , 10)

Preview_close = ->
    __clear_timeout()
    if Preview_container.is_showing
        __CLOSE_PREVIEW_ID = setTimeout(->
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
            @normalImg = create_img(src:PREVIEW_CLOSE_BUTTON, @close_button)
            @hoverImg = create_img(src:PREVIEW_CLOSE_HOVER_BUTTON, @close_button)
            @hoverImg.style.display = 'none'
            @close_button.addEventListener('click', (e)=>
                e.stopPropagation()
                @canvas = null
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
            @setTitle(@title_str)
            @update_size()

            if not activeWindow
                activeWindow= new ActiveWindow(clientManager.CurrentActiveWindow_sync())

            if activeWindow.itemId and activeWindow.active_window == @w_id
                @to_active()
            else
                @to_normal()

        Preview_container.append(@)
        if @applet
        else
            Preview_container._calc_size()

    setTitle:(title)=>
        @title_str = title
        @title.setAttribute("title", title)
        @title.innerText = title

    delay_destroy: ->
        setTimeout(=>
            @destroy()
        , 100)

    destroy: ->
        super
        Preview_container.remove(@)
        if Preview_container.is_showing
            Preview_container._calc_size()

    update_size: ->
        if Preview_container.scale == -1
            @element.style.margin = "15px"
            @element.style.width = Preview_container.pw_width + PREVIEW_WINDOW_BORDER_WIDTH * 2
            @element.style.height = Preview_container.pw_height + PREVIEW_WINDOW_BORDER_WIDTH * 2
            @canvas_width = Preview_container.pw_width
            @canvas_height = Preview_container.pw_height
        else
            @scale = Preview_container.scale || 1
            @element.style.margin = "#{15*@scale}px"
            @element.style.width = PREVIEW_WINDOW_WIDTH * @scale
            @element.style.height = PREVIEW_WINDOW_HEIGHT * @scale
            @canvas_width = PREVIEW_CANVAS_WIDTH * @scale
            @canvas_height = PREVIEW_CANVAS_HEIGHT * @scale
        if not @applet
            @canvas.setAttribute("width", @canvas_width)
            @canvas.setAttribute("height", @canvas_height)
            @canvas_container.style.width = @canvas_width
            @canvas_container.style.height = @canvas_height
        if @applet
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
        DCore.Dock.set_is_hovered(false)
        Preview_close_now(Preview_container._current_group)

    do_rightclick: (e)=>
        clientManager?.ActiveWindow(@w_id)

    do_mouseover: (e)=>
        __clear_timeout()
        Preview_container.is_showing = true
        DCore.Dock.require_all_region()
        clearTimeout(normal_mouseout_id)
        if not @applet
            Preview_active_window_changed(@w_id)

    update_content: =>
        if not Preview_container.is_showing
            return

        if @scale != Preview_container.scale
            @update_size()

        if @applet
            return

        infos = Preview_container._current_group.client_infos
        if @w_id != 0 and infos[@w_id]
            DCore.Dock.draw_window_preview(@canvas, @w_id, @canvas_width, @canvas_height)
            title = infos[@w_id].title
            if title != @title_str
                @setTitle(title)
        else
            console.log("#{@w_id} is not eixsted")


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
