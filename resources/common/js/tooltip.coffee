tooltip_hide_id = null
class ToolTip extends Widget
    tooltip: null
    should_show_id: -1
    constructor: (@widget, @text)->
        ToolTip.tooltip ?= $("#tooltip")

        @event_bind('dragstart', =>
            clearTimeout(ToolTip.should_show_id)
            ToolTip.tooltip?.style.display = "none"
        )
        @event_bind('dragenter', =>
            clearTimeout(ToolTip.should_show_id)
            ToolTip.tooltip?.style.display = "none"
        )
        @event_bind('dragover', =>
            clearTimeout(ToolTip.should_show_id)
            ToolTip.tooltip?.style.display = "none"
        )
        @event_bind('dragleave', =>
            clearTimeout(ToolTip.should_show_id)
            ToolTip.tooltip?.style.display = "none"
        )
        @event_bind('dragend', =>
            @widget?.tooltip?.hide()
        )
        @event_bind('contextmenu', =>
            @widget?.tooltip?.hide()
        )
        @event_bind('mouseout', =>
            @widget?.tooltip?.hide()
        )
        @event_bind('mouseover', =>
            ToolTip.should_show_id = setTimeout(=>
                @widget?.tooltip?.show()
            , 500)
        )
        @event_bind('click', =>
            @widget?.tooltip?.hide()
        )

    event_bind: (evt_name, callback) ->
        @widget.element.addEventListener(evt_name, (e) ->
            callback()
        )

    show: ->
        Preview_close_now()
        ToolTip.tooltip.innerText = @text
        DCore.Dock.require_all_region()
        ToolTip.tooltip.style.display = "block"
        @_move_tooltip()
    hide: ->
        clearTimeout(ToolTip.should_show_id)
        ToolTip.tooltip.style.display = "none"
        sleep_time = 400
        if Preview_container.is_showing
            sleep_time = 1000
        tooltip_hide_id = setTimeout(->
            update_dock_region()
            DCore.Dock.update_hide_mode()
        , sleep_time)
    @move_to: (x, y) ->
        if y <= 0
            @hide()
            return
        ToolTip.tooltip.style.left = "#{x}px"
        ToolTip.tooltip.style.bottom = "#{y}px"
    _move_tooltip: ->
        item_x = get_page_xy(@widget.element, 0, 0).x
        offset = (@widget.element.clientWidth - ToolTip.tooltip.clientWidth) / 2

        x = item_x + offset + 4  # 4 for subtle adapt
        x = 0 if x < 0
        ToolTip.move_to(x.toFixed(), @widget.element.clientHeight)

