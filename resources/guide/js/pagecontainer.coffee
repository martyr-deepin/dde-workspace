class Page extends Widget
    constructor: (@id)->
        super
        
        @element.style.display = "-webkit-box"
        @element.style.width = "100%"
        @element.style.height = "100%"
        @element.style.webkitBoxPack = "center"
        @element.style.webkitBoxAlign = "center"
        #@element.style.webkitBoxOrient = "horizontal"

    show_message: (@message) ->
        @message_div = create_element("div","message_#{@id}",@element) if not @message_div?
        @message_div.innerText = @message
        @message_div.style.textAlign = "center"
        @message_div.style.fontSize = "2em"
        @message_div.style.color = "#fff"
        @message_div.style.textShadow = "0 1px 1px rgba(0,0,0,0.7)"



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

