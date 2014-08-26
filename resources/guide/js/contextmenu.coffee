
MENU =
    cutline:0
    option:1
    selected:2
class ContextMenu extends Widget

    constructor: (@id,@parent)->
        super
        @parent?.appendChild(@element)
        inject_css(@element,"css/contextmenu.css")

    underline : (str) ->
        return "<u>" + str + "</u>"

    menu_create: (@menu_text) ->
        @li = []
        @menubg = create_element("div","menubg",@element)
        @ul = create_element("ul","",@menubg)
        for menu,i in @menu_text
            @li[i] = create_element("li","",@ul)
            @li[i].style.cursor = "default"

            _index = menu.text.indexOf("_")
            _before = menu.text.slice(0,_index)
            _char = menu.text.substr(_index,2)
            _behind = menu.text.slice(_index + 2)

            _char = @underline(_char.slice(1))
            #_char = _char.slice(1)
            menu.text = _before.concat(_char,_behind)
            switch menu.type
                when MENU.cutline then @li[i].setAttribute("class","cutline")
                when MENU.option
                    @cancle_seleted(i)
                    @li[i].innerHTML = menu.text
                when MENU.selected
                    @li[i].style.cursor = "pointer"
                    @li[i].classList.add("selected")
                    @li[i].innerHTML = menu.text

    set_selected: (i,time = 1,cb) ->
        setTimeout(=>
            console.debug "@set_selected(#{i})"
            @selected_index = i
            for li,j in @li
                if j == i
                    li.style.cursor = "pointer"
                    li.classList.add("selected")
                else
                    li.classList.remove("selected")
            cb?()
        ,time)

    cancle_seleted: (i) ->
        if "selected" in @li[i].classList
            @li[i].classList.remove("selected")

    set_pos : (x,y,position_type = "fixed",type = POS_TYPE.leftup) ->
        set_pos(@element,x,y,position_type,type)

    selected_click: (cb) ->
        @li[@selected_index].addEventListener("click",=>
            cb?()
        )

    selected_auto: (start,end,t_move,cb) ->
        j = 0
        for i in [start...end]
            if @li[i].getAttribute("class") == "cutline"
                continue
            else
                j++
                @set_selected(i,t_move * j)
        setTimeout(->
            cb?()
        ,t_move * j)
