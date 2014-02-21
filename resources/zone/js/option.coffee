class Option extends Widget
    constructor:(@id,@current)->
        super
        echo "new Option:#{@id}, current:#{@current}"
        @opt = []
        @opt_div = []
        @opt_text = []
        document.body.style.fontSize = "62.5%"
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

        @element.addEventListener("mouseover",=>
            clearInterval(@timeOut) if @timeOut
            @opt_choose.style.display = "block"
            @current_img.style.backgroundPosition = @bg_pos_hover
            for opt,i in @opt
                if opt is @current then @opt_text[i].style.color = "green"
                else @opt_text[i].style.color = "#fff"
        )
        @element.addEventListener("mouseout",=>
            @timeOut = setTimeout(=>
                @current_img.style.backgroundPosition = @bg_pos_normal
                @opt_choose.style.display = "none"
            ,50)
        )

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
            return "#{n * 101}px"
        Hover_X = 0
        Hover_Y = 2
        switch @id
            when "LEFTUP"
                @bg_pos_normal = "#{Delta(-1)} #{Delta(-1)}"
                @bg_pos_hover = "#{Delta(-1 + Hover_X)} #{Delta(-1 + Hover_Y)}"
            when "LEFTDOWN"
                @bg_pos_normal = "#{Delta(-1)} #{Delta(0)}"
                @bg_pos_hover = "#{Delta(-1 + Hover_X)} #{Delta(0 + Hover_Y)}"
            when "RIGHTUP"
                @bg_pos_normal = "#{Delta(0)} #{Delta(-1)}"
                @bg_pos_hover = "#{Delta(0 + Hover_X)} #{Delta(-1 + Hover_Y)}"
            when "RIGHTDOWN"
                @bg_pos_normal = "#{Delta(0)} #{Delta(0)}"
                @bg_pos_hover = "#{Delta(0 + Hover_X)} #{Delta(0 + Hover_Y)}"
        @current_img.style.backgroundPosition = @bg_pos_normal
    
    opt_choose_div_build :->
        @opt_choose = create_element("div","opt_choose",@element)
        margin = "101px"
        if @current_left
            @opt_choose.style.left = margin
            #@opt_choose.style.marginLeft = margin
            @opt_choose.style.textAlign = "left"
        else
            @opt_choose.style.right = "-37px"
            #@opt_choose.style.marginRight = "-10em"
            @opt_choose.style.textAlign = "right"
        
        if !@current_up then @opt.reverse()
        for opt,i in @opt
            #echo i + ":" + opt
            @opt_text[i] = create_element("div","opt_text",@opt_choose)
            @opt_text[i].textContent = opt
            @opt_text[i].value = i
            if opt is @current then @opt_text[i].style.color = "green"
            else @opt_text[i].style.color = "#fff"
            
            that = @
            @opt_text[i].addEventListener("click",(e)->
                e.stopPropagation()
                that.current = this.textContent
                that.opt_choose.style.display = "none"
                that.current_text.textContent = that.current
            )
        @opt_choose.style.display = "none"
