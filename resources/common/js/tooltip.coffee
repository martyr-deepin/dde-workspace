tooltip_hide_id = null
class ToolTip extends Widget
    tooltip: null
    should_show_id: -1
    constructor: (@element, @text)->
        ToolTip.tooltip ?= $("#tooltip")

        @event_bind('dragstart', =>
            @_hide_tooltip()
        )
        @event_bind('dragenter', =>
            @_hide_tooltip()
        )
        @event_bind('dragover', =>
            @_hide_tooltip()
        )
        @event_bind('dragleave', =>
            @_hide_tooltip()
        )
        @event_bind('dragend', =>
            @hide()
        )
        @event_bind('contextmenu', =>
            @hide()
        )
        @event_bind('mouseout', =>
            @hide()
        )
        @event_bind('mouseover', =>
            ToolTip.should_show_id = setTimeout(=>
                @show()
            , 500)
        )
        @event_bind('click', =>
            @hide()
        )

    event_bind: (evt_name, callback) ->
        @element.addEventListener(evt_name, (e) ->
            callback()
        )

    show: ->
        Preview_close_now()
        ToolTip.tooltip.innerText = @text
        DCore.Dock.require_all_region()
        ToolTip.tooltip.style.display = "block"
        @_move_tooltip()
    _hide_tooltip: ->
        clearTimeout(ToolTip.should_show_id)
        ToolTip.tooltip?.style.display = "none"
    hide: ->
        @_hide_tooltip()
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
        item_x = get_page_xy(@element, 0, 0).x
        offset = (@element.clientWidth - ToolTip.tooltip.clientWidth) / 2

        x = item_x + offset + 4  # 4 for subtle adapt
        x = 0 if x < 0
        ToolTip.move_to(x.toFixed(), @element.clientHeight)

