
_global_menu_container = create_element("div", "", document.body)
_global_menu_container.id = "global_menu_container"
_global_menu_container.addEventListener("click", (e)->
    _global_menu_container.style.display = "none"
    _global_menu_container.removeChild(_global_menu_container.children[0])
)
    

class Menu extends Widget
    constructor: (@id)->
        super
        @items = []
        
    insert: (@id, @title, @img)->
        _id = @id
        _title = @title
        item = create_element("div", "menuitem", @element)
        item.addEventListener("click", (e)=>
            @cb(_id, _title)
        )
        create_img("menuimg", @img, item)
        title = create_element("div", "menutitle", item)
        title.innerText = @title
        @items[@id] = item

    set_callback: (cb)->
        @cb = cb

    show: (e)->
        _global_menu_container.appendChild(@element)
        _global_menu_container.style.display = "block"
        #TODO: calc the postion
        @element.style.left = e.screenX
        @element.style.top = e.screenY


class ComboBox extends Widget
        constructor: (@id, @on_click_cb) ->
                super
                @show_item = create_element("div", "ShowItem", @element)
                @current_img = create_img("", "", @show_item)
                @switch = create_element("div", "Switcher", @element)
                @menu = new Menu(@id+"_menu")
                @menu.set_callback(@on_click_cb)

        insert: (id, title, img)->
            @current_img.src = img
            @menu.insert(id, title, img)

        do_click: (e)->
            if e.target == @switch
                @menu.show(e)


