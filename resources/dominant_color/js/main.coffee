update_bv_range = ->
    DCore.DominantColor.set_range(_bv_range.sb, _bv_range.sr, _bv_range.vb, _bv_range.vr)
    for s in $s(".ShowContainer")
        echo s
        Widget.look_up(s.id)?.update()

_bv_range =
    "sb": 0.15
    "sr": 0.1
    "vb": 0.8
    "vr": 0.1


jQuery("#b_slider").slider(
    range: true
    values: [0, 100]
    change: (e, ui) ->
        b_value.innerText = "[#{ui.values[0] / 100}, #{ui.values[1]/100}]"
        _bv_range.sb = ui.values[0] / 100
        _bv_range.sr = ui.values[1] / 100 - _bv_range.sb
        update_bv_range()
)

jQuery("#s_slider").slider(
    range: true
    values: [0, 100]
    change: (e, ui) ->
        s_value.innerText = "[#{ui.values[0] / 100}, #{ui.values[1]/100}]"
        _bv_range.vb = ui.values[0] / 100
        _bv_range.vr = ui.values[1] / 100 - _bv_range.sb
        update_bv_range()
)



class ShowContainer extends Widget
    constructor: (@id, @img)->
        super
        @r = create_element("div", "close", @element)
        @r.innerText = "X"
        @s1 = create_element("div", "ShowItem", @element)
        @c1 = @create_canvas(@s1)
        @cc1 = create_element("div", "ColorInfo", @s1)

        @s2 = create_element("div", "ShowItem", @element)
        @c2 = @create_canvas(@s2)
        @cc2 = create_element("div", "ColorInfo", @s2)

        @s3 = create_element("div", "ShowItem", @element)
        @c3 = @create_canvas(@s3)
        @cc3 = create_element("div", "ColorInfo", @s3)

        @s4 = create_element("div", "ShowItem", @element)
        @c4 = @create_canvas(@s4)
        @cc4 = create_element("div", "ColorInfo", @s4)

        @update()

    do_click: (e)->
        if e.target = @r
            @destroy()

    set_img: (img)->
        @img = img
        @update()

    create_canvas: (p)->
        c = create_element("canvas", "", p)
        c.width = 48
        c.height = 48
        return c

    update: ->
        c1 = DCore.DominantColor.get_color(@img, 1)
        t = "(#{c1.r.toFixed()}, #{c1.g.toFixed()}, #{c1.b.toFixed()})"
        @cc1.style.background = "rgb#{t}"
        @cc1.innerText = t

        c2 = DCore.DominantColor.get_color(@img, 2)
        t = "(#{c2.r.toFixed()}, #{c2.g.toFixed()}, #{c2.b.toFixed()})"
        @cc2.style.background = "rgb#{t}"
        @cc2.innerText = t

        c3 = DCore.DominantColor.get_color(@img, 3)
        t = "(#{c3.r.toFixed()}, #{c3.g.toFixed()}, #{c3.b.toFixed()})"
        @cc3.style.background = "rgb#{t}"
        @cc3.innerText = t

        c4 = DCore.DominantColor.get_color(@img, 4)
        t = "(#{c4.r.toFixed()}, #{c4.g.toFixed()}, #{c4.b.toFixed()})"
        @cc4.style.background = "rgb#{t}"
        @cc4.innerText = t

        DCore.DominantColor.draw1(@c1, @img, 32)
        DCore.DominantColor.draw2(@c2, @img, 32)
        DCore.DominantColor.draw3(@c3, @img, 32)
        DCore.DominantColor.draw4(@c4, @img, 32)

class AddImg extends Widget
    constructor: (@id)->
        super
        @add_css_class("DragZone")
        @element.innerText = "拖点图片到这" 
        $("#config").appendChild(@element)
    do_drop: (e)->
        path = decodeURI(e.dataTransfer.getData("text/uri-list").substring(7).trim())
        c = new ShowContainer(path, path)
        show.appendChild(c.element)

class AddBoard extends Widget
    constructor: (@id)->
        super
        @add_css_class("DragZone")
        @element.innerText = "设置底板"
        $("#config").appendChild(@element)
    do_drop: (e)->
        raw = e.dataTransfer.getData("text/uri-list").trim()
        path = decodeURI(raw.substring(7))
        @element.style.backgroundImage = "url(#{raw})"
        @element.style.border = ""
        DCore.DominantColor.set_board(path)
        update_bv_range()

class AddMask extends Widget
    constructor: (@id)->
        super
        @add_css_class("DragZone")
        @element.innerText = "设置mask"
        $("#config").appendChild(@element)
    do_drop: (e)->
        raw = e.dataTransfer.getData("text/uri-list").trim()
        path = decodeURI(raw.substring(7))
        @element.style.backgroundImage = "url(#{raw})"
        @element.style.border = ""
        DCore.DominantColor.set_mask(path)
        update_bv_range()

new AddImg("_add_img")
new AddBoard("_addboard")
new AddMask("_addMask")
