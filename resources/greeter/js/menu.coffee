_global_menu_container = create_element("div", "", document.body)
_global_menu_container.id = "global_menu_container"
_global_menu_container.addEventListener("click", (e)->
    _global_menu_container.style.display = "none"
    _global_menu_container.removeChild(_global_menu_container.children[0])
)

class Menu extends Widget
    constructor: (@id) ->
        super
        @current = @id
        @items = {}
    
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

        _img = @img
        @items[_id] = [_title, _img] 
        @current = @id
    
    set_callback: (@cb)->

    show: (x, y)->
        @try_append()
        
        @element.style.left = x
        @element.style.top = y

    try_append: ->
        if not @element.parent
            _global_menu_container.appendChild(@element)
            _global_menu_container.style.display = "block"

    get_allocation: ->
        @try_append()

        width = @element.clientWidth
        height = @element.clientHeight

        "width":width
        "height":height
 
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
            p = get_page_xy(e.target, 0, 0)
            alloc = @menu.get_allocation()
            x = p.x - alloc.width/2
            y = p.y - alloc.height

            @menu.show(x, y)

    get_current: ->
        return @menu.current

    set_current: (id)->
        _img = @menu.items[id][1]
        @current_img.src = _img
        @menu.current = id

#DCore.signal_connect("status", (msg) ->
#    status_div = create_element("div", " ", $("#Debug"))
#    status_div.innerText = "status:" + msg.status
#)
    
