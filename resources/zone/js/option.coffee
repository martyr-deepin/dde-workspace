class Option extends Widget
    constructor(@id,@current):->
        echo "new Option:#{@id}"
        @opt = []
        @opt_div = []

    insert:(opt)->
        @opt.push(opt)

    opt_build:->
        @current_div = create_element("div","current_div",@element)
        @current_img = create_element("current_img","",@current_div)
        @current_img.src = "img/set.png"
        @current_text = create_element("div","current_text",@current_div)
        @current_text.textContent = @current
        
        @opt_choose = create_element("div","opt_choose",@element)
        margin = "10.1em"
        switch @id
            when "LEFTUP"
                # up right down left
                @textAlign = "right"
                @margin = "0 margin 0 0"
            when "LEFTDOWN"
                @textAlign = "right"
                @margin = "0 margin 0 0"
            
            when "RIGHTUP"
                @textAlign = "left"
                @margin = "0 0 0 margin"

            when "RIGHTDOWN"
                @textAlign = "left"
                @margin = "0 0 0 margin"
         
        @opt_choose.style.textAlign = @textAlign
        @opt_choose.style.marginRight = @margin
        for opt,i in @opt
            @opt_text[i] = create_element("div","opt_text",@opt_choose)
            @opt_text[i].textContent = opt
            if opt is @current then @opt_text[i].style.fontColor = "green"
            
           @opt_text[i].addEventListener("click",=>
                @current = @opt_text[i].textContent
                @opt_choose.style.display = "none"
            )
            
            
            
            
            
        @opt_choose.addEventListener("mouseover",=>
            @opt_choose.style.display = "block"
            clearInterval(@timeOut) if @timeOut
        )
        @current_div.addEventListener("mouseover",=>
            @opt_choose.style.display = "block"
        )
        @current_div.addEventListener("mouseout",=>
            @timeOut = setTimeout(=>
                @opt_choose.style.display = "none"
            ,500)
        )
