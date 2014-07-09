

class ButtonNext extends Widget
    normal_interval = null
    normal_hover_interval = null
    constructor: (@id,@text,@parent)->
        super
        @parent?.appendChild(@element)
        @img_src = "img"
        @img_normal = "#{@img_src}/next_normal.png"
        @img_hover = "#{@img_src}/next_hover.png"
        @img_press = "#{@img_src}/next_press.png"

    set_img:(@img_normal,@img_hover,@img_press) ->

    create_button:(@cb,@show_animation = false) ->
        @element.style.display = "-webkit-box"
        @element.style.height = "64px"
        @element.style.color = "#fff"
        @element.style.textShadow = "0 1px 1px rgba(0,0,0,0.7)"
        @bn_text = create_element("div","bn_text",@element)
        @bn_text.innerText = @text
        @bn_text.style.fontSize = "2.2em"
        @bn_text.style.lineHeight = "3.0em"
        @bn_text.style.textAlign = "right"

        @bn_div = create_element("div","bn_div",@element)
        @bn_div.style.width = "6.4em"
        @bn_div.style.height = "6.4em"
        @bn_div.style.backgroundImage = "url(#{@img_normal})"
        if @show_animation then @normal_animation()
        @bn_div.addEventListener("mouseover",=>
            @bn_div.style.cursor = "pointer"
            @stop_animation()
            @bn_div.style.backgroundImage = "url(#{@img_hover})"
        )
        @bn_div.addEventListener("mouseout",=>
            @bn_div.style.cursor = "normal"
            @bn_div.style.backgroundImage = "url(#{@img_normal})"
            @stop_animation()
            if @show_animation then @normal_animation()
        )
        @bn_div.addEventListener("click",(e) =>
            e.stopPropagation()
            @bn_div.style.backgroundImage = "url(#{@img_press})"
            @cb?()
        )

    stop_animation: ->
        jQuery(@bn_div).stop(true,true)
        clearInterval(normal_interval)

    normal_animation: ->
        t = 1000
        @bn_div.style.opacity = 1.0
        @bn_div.style.backgroundImage = "url(#{@img_normal})"
        animation_hover_to_normal = =>
            jQuery(@bn_div).animate(
                {opacity:0.0},t,"linear",=>
                    @bn_div.style.backgroundImage = "url(#{@img_hover})"
                    jQuery(@bn_div).animate(
                        {opacity:1.0},t,"linear",=>
                            @bn_div.style.backgroundImage = "url(#{@img_normal})"
                    )
            )
        animation_hover_to_normal()
        normal_interval = setInterval(=>
            animation_hover_to_normal()
        ,t * 2)

