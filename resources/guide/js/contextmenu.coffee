
MENU =
    cutline:0
    option:1
    selected:2
class ContextMenu extends Widget
    
    constructor: (@id,@parent)->
        super
        @parent?.appendChild(@element)
        inject_css(@element,"css/contextmenu.css")
        
    menu_create: (@menu_text) ->
        @li = []
        @menubg = create_element("div","menubg",@element)
        @ul = create_element("ul","",@menubg)
        for menu,i in @menu_text
            @li[i] = create_element("li","",@ul)
            @li[i].style.cursor = "default"
            switch menu.type
                when MENU.cutline then @li[i].setAttribute("class","cutline")
                when MENU.option
                    @li[i].setAttribute("class","")
                    @li[i].textContent = menu.text
            
                when MENU.selected
                    @selected_index = i
                    @li[i].style.cursor = "pointer"
                    @li[i].setAttribute("class","selected")
                    @li[i].textContent = menu.text
    
    set_pos : (x,y,position_type = "fixed",type = POS_TYPE.leftup) ->
        set_pos(@element,x,y,position_type,type)

    selected_click: (cb) ->
        @li[@selected_index].addEventListener("click",=>
            cb?()
        )


