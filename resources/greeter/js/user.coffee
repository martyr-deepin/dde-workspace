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
        @login.innerText = "User Login"
        @login.addEventListener("click", =>
            @on_active(@password.value)
        )
        @login.index = 1

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

    focus: ->
        _current_user?.blur()
        _current_user = @
        @add_css_class("UserInfoSelected")

    blur: ->
        @element.setAttribute("class", "UserInfo")
        @login?.destroy()
        @login = null
        @loadding?.destroy()
        @loading = null

    show_login: ->
        if false
            @login()
        else if not @login
            @login = new LoginEntry("login", (p)=>@on_verify(p))
            @element.appendChild(@login.element)

    do_click: (e)->
        if _current_user == @
            @show_login()
        else
            @focus()

    on_verify: (password)->
        @login.destroy()
        loading = new Loading("loading")
        @element.appendChild(loading.element)



# below code should use c-backend to fetch data 
users = DCore.Greeter.get_users()
for user in users
    u = new UserInfo(user, user, "images/img01.jpg")
    roundabout.appendChild(u.li)

# default_user = DCore.Greeter.get_default_user()    
# first = new UserInfo(default_user, default_user, "images/img01.jpg")
# first.focus()    
    
# u = new UserInfo(1000, "Alice Charlotte", "images/img01.jpg")
# u2 = new UserInfo(1001, "Snyh", "images/guest.jpg")
# u3 = new UserInfo(1001, "Snyh", "images/img04.jpg")
# u4 = new UserInfo(1001, "Snyh", "images/img02.jpg")
# u5 = new UserInfo(1001, "Snyh", "images/img03.jpg")

# roundabout.appendChild(u.li)
# u.focus()

# roundabout.appendChild(u2.li)
# roundabout.appendChild(u3.li)
# roundabout.appendChild(u4.li)
# roundabout.appendChild(u5.li)

# end this

if roundabout.children.length == 2
    roundabout.style.width = "0"

run_post(->
    l = (screen.width  - roundabout.clientWidth) / 2
    roundabout.style.left = "#{l}px"
)
