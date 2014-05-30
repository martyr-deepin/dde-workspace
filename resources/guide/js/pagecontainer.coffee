
class Page extends Widget
    constructor: (@id)->
        super
        echo "new #{@id} Page"
        @img_src = "img"
        
        @element.style.display = "-webkit-box"
        @element.style.width = "100%"
        @element.style.height = "100%"
        @element.style.webkitBoxPack = "center"
        @element.style.webkitBoxAlign = "center"
        #@element.style.webkitBoxOrient = "vertical"
        @msg_tips = create_element("div","msg_tips",@element)
        @msg_tips.style.color = "#fff"
        @msg_tips.style.textAlign = "center"
        @msg_tips.style.textShadow = "0 1px 1px rgba(0,0,0,0.7)"
        

    show_message: (@message) ->
        @message_div = create_element("div","message_#{@id}",@msg_tips)
        @message_div.innerText = @message
        @message_div.style.fontSize = "2em"
        @message_div.style.lineHeight = "2.3em"

    show_tips: (@tips) ->
        @tips_div = create_element("div","tips_#{@id}",@msg_tips)
        @tips_div.innerText = @tips
        @tips_div.style.fontSize = "1.6em"
        @tips_div.style.lineHeight = "1.9em"
        @tips_div.style.position = "relative"
        @tips_div.style.marginTop = "40px"


    set_message_pos : (x,y,position_type = "fixed",type = POS_TYPE.leftup) ->
        set_pos(@message_div,x,y,position_type,type)
        
class PageContainer extends Widget
    constructor: (@id)->
        super

    add_page: (page_id) ->
        try
            @element.appendChild(page_id.element)
        catch error
            echo error

    remove_page: (page_id) ->
        try
            @element.removeChild(page_id.element)
        catch error
            echo error

    switch_page: (old_page, new_page) ->
        echo "switch page"

    current_page: ->
        echo "current_page"

