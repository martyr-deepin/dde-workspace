jQuery("#b_slider").slider(
    range: true
    values: [0, 100]
    change: (e, ui) ->
        b_value.innerText = "[#{ui.values[0] / 100}, #{ui.values[1]/100}]"
)

jQuery("#s_slider").slider(
    range: true
    values: [0, 100]
    change: (e, ui) ->
        s_value.innerText = "[#{ui.values[0] / 100}, #{ui.values[1]/100}]"
)


class ShowContainer extends Widget
    constructor: (@id, @img)->
        super
        @s1 = create_element("div", "ShowItem", @element)
        @c1 = @create_canvas(@s1)
        @s2 = create_element("div", "ShowItem", @element)
        @c2 = @create_canvas(@s2)
        @s3 = create_element("div", "ShowItem", @element)
        @c3 = @create_canvas(@s3)
        @s4 = create_element("div", "ShowItem", @element)
        @c4 = @create_canvas(@s4)
        @update()

    set_img: (img)->
        @img = img
        @update()

    create_canvas: (p)->
        c = create_element("canvas", "", p)
        c.width = 48
        c.height = 48
        return c

    update: ->
        DCore.DominantColor.draw1(@c1, @img)
        DCore.DominantColor.draw2(@c2, @img)
        DCore.DominantColor.draw3(@c3, @img)
        DCore.DominantColor.draw4(@c4, @img)

s = new ShowContainer("snyh", "/dev/shm/t1.png")
show.appendChild(s.element)
s2 = new ShowContainer("snyh", "img/t2.png")
show.appendChild(s2.element)
s3 = new ShowContainer("snyh", "img/t3.png")
show.appendChild(s3.element)
s4 = new ShowContainer("snyh", "img/t4.png")
show.appendChild(s4.element)
