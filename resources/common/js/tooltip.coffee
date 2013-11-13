tooltip_hide_id = null
class ToolTip extends Widget
    @tooltip: null
    constructor: (@buddy, @text, @parent=document.body)->
        super
        @delay_time = 0
        @delay_id = null
        ToolTip.tooltip ?= create_element("div", "tooltip", @parent)
        @bind_events()

    set_delay_time: (millseconds) ->
        @delay_time = millseconds

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
            @delay_id = setTimeout(=>
                @show()
            , @delay_time)
        )
        @buddy.addEventListener('click', @hide)

    show: ->
        ToolTip.tooltip.innerText = @text
        ToolTip.tooltip.style.display = "block"
        @_move_tooltip()

    hide: =>
        clearTimeout(@delay_id)
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
        arrow_outter = create_element("div", "pop_arrow_up_outer", @element)
        arrow_mid = create_element("div", "pop_arrow_up_mid", @element)
        arrow_inner = create_element("div", "pop_arrow_up_inner", @element)

    move_to: (left)->
        @element.style.left = "#{left}px"


class ArrowToolTip extends ToolTip
    ###
    @tooltip: null
    constructor: (@buddy, @text, @parent=document.body)->
        super(@buddy, @text, @parent)
        ToolTip.tooltip?.parent?.removeChild(ToolTip.tooltip)
        if @parent
            @parent.appendChild(@element)
        ArrowToolTip.tooltip ?= create_element('div', 'arrow_tooltip', @element)
        @arrow = new Arrow("ToolTipArrow")
        @element.appendChild(@arrow.element)

    _move_tooltip: ->
        page_xy= get_page_xy(@buddy, 0, 0)
        offset = (@buddy.clientWidth - ToolTip.tooltip.clientWidth) / 2

        x = page_xy.x + offset
        x = 0 if x < 0
        ToolTip.move_to(@, x.toFixed(), document.body.clientHeight - page_xy.y)
        @arrow.move_to(page_xy.x + @buddy.clientWidth - 3)
    ###
