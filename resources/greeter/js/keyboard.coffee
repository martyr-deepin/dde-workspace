nicesx = null
class Keyboard extends Widget

    constructor:(@parent)->
        super
        echo "New Keyboard"
        #inject_js("js/jquery/jquery.nicescroll.js")
        inject_css(@element,"css/select.css")
        @layouts = []
        @CurrentLayout = null
        @parent?.appendChild(@element)
        @get_layout()
        @hide()
 
    show: ->
        @element.style.display = "block"

    hide: ->
        @element.style.display = "none"

    get_layout: ->
        @layouts = DCore.Greeter.get_layouts()
        @CurrentLayout = DCore.Greeter.get_current_layout()

    boxscroll_create: ->
        @boxscroll = create_element("div","boxscroll",@element)
        @boxscroll.setAttribute("id","boxscroll")
        #nicesx = @boxscroll.niceScroll({touchbehavior:false,cursorcolor:"#fff",cursoropacitymax:0.6,cursorwidth:8})
        @li = []
        @a = []
        @ul = create_element("ul","",@boxscroll)
        for layout,i in @layouts
            @li[i] = create_element("li","",@ul)
            @a[i] = create_element("a","",@li[i])
            @li[i].title = layout
            @a[i].innerText = layout
            if layout is @CurrentLayout then @select_css(@li[i])
            that = @
            @li[i].addEventListener("click",->
                that.select_css(this)
                DCore.Greeter.set_layout(layout)
            )
    
    select_css: (el) ->
        el.style.background = "rgba(0,0,0,0.3)"

