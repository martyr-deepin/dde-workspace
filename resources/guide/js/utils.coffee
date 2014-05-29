
set_pos = (el,x,y,type = "lefttop",position_type = "fixed")->
    el.style.position = position_type
    switch type
        when "lefttop"
            el.style.left = x
            el.style.top = y
        
        when "leftbottom"
            el.style.left = x
            el.style.bottom = y

        when "righttop"
            el.style.right = x
            el.style.top = y
        
        when "rightbottom"
            el.style.right = x
            el.style.bottom = y

        else
            el.style.left = x
            el.style.top = y
        
