tooltip_hide_id = null
class ToolTipBase extends Widget
    delay_time: 0
    constructor: (@buddy, @text, @parent=document.body)->
        super

    set_delay_time: (millseconds) ->
        ToolTipBase.delay_time = millseconds

    set_text: (text)->
        @text = text

    bind_events: ->
        @buddy.addEventListener('dragstart', @hide)
        @buddy.addEventListener('dragenter', @hide)
        @buddy.addEventListener('dragover', @hide)
        @buddy.addEventListener('dragleave', @hide)
        @buddy.addEventListener('dragend', @hide)
        @buddy.addEventListener('contextmenu', @hide)
        @buddy.addEventListener('mouseout', @hide)
        @buddy.addEventListener('mouseover', =>
            if @text == ''
                return
            clearTimeout(tooltip_hide_id)
            tooltip_hide_id = setTimeout(=>
                @show()
            , ToolTipBase.delay_time)
        )
        @buddy.addEventListener('click', @hide)

    hide: =>
        clearTimeout(tooltip_hide_id)


class ToolTip extends ToolTipBase
    @tooltip: null
    constructor: (@buddy, @text, @parent=document.body)->
        super
        ToolTip.tooltip ?= create_element("div", "tooltip", @parent)
        @bind_events()

    show: ->
        ToolTip.tooltip.innerText = @text
        ToolTip.tooltip.style.display = "block"
        @_move_tooltip()

    hide: =>
        super
        ToolTip.tooltip?.style.display = "none"

    @move_to: (self, x, y) ->
        if y <= 0
            self.hide()
            return
        ToolTip.tooltip.style.left = "#{x}px"
        ToolTip.tooltip.style.bottom = "#{y}px"

    _move_tooltip: ->
        page_xy= get_page_xy(@buddy, 0, 0)
        offset = (@buddy.clientWidth - ToolTip.tooltip.clientWidth) / 2

        x = page_xy.x + offset
        x = 0 if x < 0
        ToolTip.move_to(@, x.toFixed(), document.body.clientHeight - page_xy.y)


class Arrow extends Widget
    constructor: (@id)->
        super
        @arrow_outter = create_element("div", "pop_arrow_up_outer", @element)
        @arrow_mid = create_element("div", "pop_arrow_up_mid", @element)
        @arrow_inner = create_element("div", "pop_arrow_up_inner", @element)

    move_to: (x, y)->
        @element.style.left = "#{x}px"
        if y
            @element.style.top = "#{y}px"


class ArrowToolTip extends ToolTipBase
    @container: null
    @tooltip: null
    @arrow: null
    constructor: (@buddy, @text, @parent=document.body)->
        super(@buddy, @text, @parent)
        ArrowToolTip.container ?= create_element('div', 'arrow_tooltip_container ', @parent)
        ArrowToolTip.tooltip ?= create_element('div', 'arrow_tooltip', ArrowToolTip.container)
        # ArrowToolTip.tooltip.classList.add('arrow_tooltip')
        ArrowToolTip.arrow ?= create_element('div', 'triangle', ArrowToolTip.container)
        @bind_events()

    show: ->
        ArrowToolTip.tooltip.innerText = @text
        ArrowToolTip.tooltip.style.display = "block"
        ArrowToolTip.container.style.display = "block"
        ArrowToolTip.container.style.opacity = 1
        @_move_tooltip()

    hide: =>
        return
        super
        ArrowToolTip.container.style.display = 'none'
        ArrowToolTip.container.style.opacity = 0
        ArrowToolTip.tooltip.style.display = 'none'
        ArrowToolTip.arrow.style.display = 'none'

    @move_to: (self, x, y) ->
        if y <= 0
            self.hide()
            return
        ArrowToolTip.container.style.left = "#{x}px"
        ArrowToolTip.container.style.bottom = "#{y}px"

    _move_tooltip: ->
        page_xy= get_page_xy(@buddy, 0, 0)
        offset = (@buddy.clientWidth - ArrowToolTip.container.clientWidth) / 2

        x = page_xy.x + offset
        x = 0 if x < 0
        y = document.body.clientHeight - page_xy.y + 7
        ArrowToolTip.move_to(@, x.toFixed(), y)
        ArrowToolTip.arrow.style.left = "#{ArrowToolTip.tooltip.clientWidth / 2 - 5}px"
