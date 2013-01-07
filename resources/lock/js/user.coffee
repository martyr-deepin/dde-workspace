class LoginEntry extends Widget
    constructor: (@id, @on_active)->
        super
        @password = create_element("input", "Password", @element)
        @password.setAttribute("type", "password")
        @password.setAttribute("autofocus", "true")
        @password.index = 0
        @password.addEventListener("keydown", (e)=>
            if e.which == 13
                @on_active(@password.value)
        )

        @login = create_element("button", "LoginButton", @element)
        @login.innerText = "UnLock"
        @login.addEventListener("click", =>
            @on_active(@password.value)
        )
        @login.index = 1
        @password.focus()
    
class Loading extends Widget
    constructor: (@id)->
        super
        create_element("div", "ball", @element)
        create_element("div", "ball1", @element)
        create_element("span", "", @element).innerText = "Welcome !"

_current_user = null
class UserInfo extends Widget
    constructor: (@id, name, img_src)->
        super
        @li = create_element("li", "")
        @li.appendChild(@element)
        @img = create_img("UserImg", img_src, @element)
        @name = create_element("span", "UserName", @element)
        @name.innerText = name
        @active = false
        @login_displayed = false

    focus: ->
        _current_user?.blur()
        _current_user = @
        @add_css_class("UserInfoSelected")

    blur: ->
        @element.setAttribute("class", "UserInfo")
        @login?.destroy()
        @login = null
        @loading?.destroy()
        @loading = null

    show_login: ->
        if false
            @login()
        else if not @login
            @login = new LoginEntry("login", (p)=>@on_verify(p))
            @element.appendChild(@login.element)
            @login_displayed = true
    
    do_click: (e)->
        if _current_user == @
            if not @login
                @show_login()
            else
                if e.target.parentElement == @login.element
                    echo "login pwd clicked"
                else
                    if @login_displayed
                        @blur()
                        @focus()
                        @login_displayed = false
        else
            @focus()
    
    on_verify: (password)->
        @login.destroy()
        @loading = new Loading("loading")
        @element.appendChild(@loading.element)
        DCore.Lock.try_unlock(password)
    
    unlock_check: (msg) ->
        if msg.status == "succeed"
            DCore.Lock.unlock_succeed()
        else
            @focus()
    
user = DCore.Lock.get_username()    
    
u = new UserInfo(user, user, "images/img01.jpg")
$("#User").appendChild(u.li)
DCore.signal_connect("unlock", (msg)->
    u.unlock_check(msg)
)
