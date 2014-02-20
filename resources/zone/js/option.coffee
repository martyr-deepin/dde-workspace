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

    current_div_build :->
        @current_div = create_element("div","current_div",@element)
        if @current_left
            @current_img = create_img("current_img","",@current_div)
            @current_text = create_element("div","current_text",@current_div)
            @current_div.style.webkitBoxPack = "start"
        else
            @current_text = create_element("div","current_text",@current_div)
            @current_img = create_img("current_img","",@current_div)
            @current_div.style.webkitBoxPack = "end"

        @current_img.src = "img/set.png"
        @current_text.textContent = @current
        
    opt_choose_div_build :->
        @opt_choose = create_element("div","opt_choose",@element)
        margin = "10.1em"
        if @current_left
            #up left down right
            #@opt_choose.style.margin = "0 #{margin} 0 0"
            @opt_choose.style.textAlign = "left"
            #@opt_choose.style.webkitBoxPack = "start"
        else
            #@opt_choose.style.margin = "0 0 0 #{margin}"
            @opt_choose.style.textAlign = "right"
            #@opt_choose.style.webkitBoxPack = "end"
        
        if !@current_up then @opt.reverse()
        for opt,i in @opt
            echo i + ":" + opt
            @opt_text[i] = create_element("div","opt_text",@opt_choose)
            @opt_text[i].textContent = opt
            @opt_text[i].value = i
            if opt is @current then @opt_text[i].style.color = "green"
            
            that = @
            @opt_text[i].addEventListener("click",->
                echo that
                echo this
                that.current = this.textContent
                that.opt_choose.style.display = "none"
                that.current_text.textContent = that.current
            )
            
        @opt_choose.style.display = "none"
        @element.addEventListener("mouseover",=>
            @opt_choose.style.display = "block"
            clearInterval(@timeOut) if @timeOut
        )
        @element.addEventListener("mouseout",=>
            @timeOut = setTimeout(=>
                @opt_choose.style.display = "none"
            ,50)
        )


