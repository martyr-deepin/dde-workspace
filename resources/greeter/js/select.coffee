nicesx = null

class Select extends Widget

    constructor:(@id,@parent)->
        super
        echo "New Select #{@id}"
        @parent?.appendChild(@element)
        #inject_js("js/jquery/jquery.nicescroll.js")
        inject_css(@element,"css/select.css")
        @lists = []
        @selected = null
        @boxscroll = null
        @hide()
    
    set_lists:(@current,@lists) ->

    toggle: ->
        if @element.style.display isnt "none" then @hide()
        else @show()

    show: ->
        @element.style.display = "block"
        @check_selected_css()
        #@boxscroll_create()

    hide: ->
        @element.style.display = "none"
        #@boxscroll_remove()

    boxscroll_remove: ->
        @element.removeChild(@boxscroll) if @boxscroll
        @boxscroll = null

    boxscroll_create: ->
        @boxscroll_remove()
        #@triangle = create_img("triangle","images/triangle.png",@element)
        @boxscroll = create_element("div","boxscroll",@element)
        @boxscroll.setAttribute("id","boxscroll")
        #if jQuery("#boxscroll").length ==0
        #    @boxscroll = create_element("div","boxscroll",@element)
        #    @boxscroll.setAttribute("id","boxscroll")
        #else @boxscroll = jQuery("#boxscroll")[0]
        @li = []
        @a = []
        @ul = create_element("ul","",@boxscroll)
        for each,i in @lists
            @li[i] = create_element("li","",@ul)
            @a[i] = create_element("a","",@li[i])
            @li[i].setAttribute("id",each)
            @a[i].innerText = each
    
    check_selected_css: ->
        @selected = @current
        if @li.length == 0 then @boxscroll_create()
        for each,i in @lists
            if each is @current then @select_css(@li[i])
            else @unselect_css(@li[i])

    unselect_css: (el) ->
        el.style.background = "rgba(0,0,0,0.5)"
    
    select_css: (el) ->
        el.style.background = "rgba(0,0,0,0.3)"
    
    set_cb:(@cb) ->
        if @li.length == 0 then @boxscroll_create()
        for each,i in @lists
            that = @
            @li[i].addEventListener("click",->
                that.current = this.id
                that.cb?(that.current)
            )
 

