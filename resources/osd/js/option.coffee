class Option extends Widget
    constructor:(@id)->
        super
        echo "new Option:#{@id}"
        @set_bg()
    
    append:(el)->
        el.appendChild(@element)

    hide:->
        @element.style.display = "none"
    
    show:->
        echo "Option show :--#{@id}--"
        @element.style.display = "block"

    set_bg:->
        @element.style.backgroundImage = "url(img/#{@id}.png)"
