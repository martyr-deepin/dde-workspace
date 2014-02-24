class Option extends Widget
    constructor:(@id,@current)->
        super
        echo "new Option:#{@id}, current:#{@current}"
        @opt = []
        @opt_div = []
        @opt_text_li = []
        @opt_text_span = []
        @element.style.position = "absolute"
        switch @id
            when "LEFTUP"
                @current_up = true
                @current_left = true
                @element.style.left = 0
                @element.style.top = 0
            when "LEFTDOWN"
                @current_up = false
                @current_left = true
                @element.style.left = 0
                @element.style.bottom= 0
            when "RIGHTUP"
                @current_up = true
                @current_left = false
                @element.style.right = 0
                @element.style.top = 0
            when "RIGHTDOWN"
                @current_up = false
                @current_left = false
                @element.style.right = 0
                @element.style.bottom = 0
     
    insert:(opt)->
        @opt.push(opt)

    option_build:->
        if @current_up
            @current_div_build()
            @opt_choose_div_build()
        else
            @opt_choose_div_build()
            @current_div_build()
        jQuery(@element).hover(@mouseenter,@mouseleave)
        
    mouseenter : =>
        echo "mouseenter"
        clearInterval(@timeOut) if @timeOut
        @current_img.style.backgroundPosition = @bg_pos_hover
        
        for opt,i in @opt
            if opt is @current then @opt_text_span[i].style.color = "#00bbfe"
            else @opt_text_span[i].style.color = "#afafaf"
        
        @opt_choose.style.display = "block"
        @opt_choose.style.opacity = "0.0"
        t_show = 200
        if @current_up
            @opt_choose.style.top = "-100px"
            jQuery(@opt_choose).animate(
                {opacity: '1.0';top:'60px';},
                t_show,
                "linear",=>
                    echo "Animation End"
            )
        else
            @opt_choose.style.bottom = "-100px"
            jQuery(@opt_choose).animate(
                {opacity: '1.0';bottom:'67px';},
                t_show,
                "linear",=>
                    echo "Animation End"
            )
        
    mouseleave : =>
        echo "mouseleave"
        @timeOut = setTimeout(=>
            @current_img.style.backgroundPosition = @bg_pos_normal
            @opt_choose.style.display = "none"
        ,50)

    current_div_build :->
        @current_div = create_element("div","current_div",@element)
        if @current_left
            @current_img = create_element("div","current_img",@current_div)
            @current_text = create_element("div","current_text",@current_div)
            @current_div.style.webkitBoxPack = "start"
        else
            @current_text = create_element("div","current_text",@current_div)
            @current_img = create_element("div","current_img",@current_div)
            @current_div.style.webkitBoxPack = "end"
        @current_text.textContent = @current
        
        Delta=(n)->
            return "#{n * 102}px"
        Hover_X = 0
        Hover_Y = 2
        left = "60px"
        top = "13px"
        bottom = "17px"
        
        switch @id
            when "LEFTUP"
                @bg_pos_normal = "#{Delta(-1)} #{Delta(-1)}"
                @bg_pos_hover = "#{Delta(-1 + Hover_X)} #{Delta(-1 + Hover_Y)}"
                @current_text.style.left = left
                @current_text.style.top = top
            when "LEFTDOWN"
                @bg_pos_normal = "#{Delta(-1)} #{Delta(0)}"
                @bg_pos_hover = "#{Delta(-1 + Hover_X)} #{Delta(0 + Hover_Y)}"
                @current_text.style.left = left
                @current_text.style.bottom = bottom
            when "RIGHTUP"
                @bg_pos_normal = "#{Delta(0)} #{Delta(-1)}"
                @bg_pos_hover = "#{Delta(0 + Hover_X)} #{Delta(-1 + Hover_Y)}"
                @current_text.style.right = left
                @current_text.style.top = top
            when "RIGHTDOWN"
                @bg_pos_normal = "#{Delta(0)} #{Delta(0)}"
                @bg_pos_hover = "#{Delta(0 + Hover_X)} #{Delta(0 + Hover_Y)}"
                @current_text.style.right = left
                @current_text.style.bottom = bottom
        @current_img.style.backgroundPosition = @bg_pos_normal
    
    opt_choose_div_build :->
        @opt_choose = create_element("ul","opt_choose",@element)
        left = "50px"
        if @current_left
            @opt_choose.style.left = left
        else
            @opt_choose.style.right = left
       
        if !@current_up then @opt.reverse()
        for opt,i in @opt
            #echo i + ":" + opt
            @opt_text_li[i] = create_element("li","opt_text_li",@opt_choose)
            @opt_text_span[i] = create_element("span","opt_text_span",@opt_text_li[i])
            @opt_text_span[i].textContent = opt
            if !@current_left then @opt_text_span[i].style.float = "right"
            that = @
            @opt_text_span[i].addEventListener("click",(e)->
                e.stopPropagation()
                that.current = this.textContent
                that.opt_choose.style.display = "none"
                that.current_text.textContent = that.current
            )
        @opt_choose.style.display = "none"
