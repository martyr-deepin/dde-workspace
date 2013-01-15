#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
#                     <snyh@snyh.org>
#Maintainer:  LongWei <yilang2007lw@gmail.com>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.
    
apply_refuse_rotate = (el, time)->
    apply_animation(el, "refuse", "#{time}s", "linear")
    setTimeout(->
        el.style.webkitAnimation = ""
    , time * 1000)

class LoginEntry extends Widget
    constructor: (@id, @on_active)->
        super
        if DCore.Greeter.is_hide_users()
            @account = create_element("input", "Account", @element)
            @account.setAttribute("autofocus", "true")
            @account.addEventListener("keydown", (e)=>
                if e.which == 13
                    @password.focus()
            )
            @account.index = 0
            
        @password = create_element("input", "Password", @element)
        @password.setAttribute("type", "password")
        #@password.setAttribute("autofocus", "true")
        @password.focus()
        @password.index = 1

        @password.addEventListener("keydown", (e)=>
            if e.which == 13
                if DCore.Greeter.is_hide_users()
                    @on_active(@account.value, @password.value)
                else
                    @on_active(@id, @password.value)
        )

        @login = create_element("button", "LoginButton", @element)
        @login.innerText = "User Login"
        @login.addEventListener("click", =>
            if DCore.Greeter.is_hide_users()
                @on_active(@account.value, @password.value)
            else
                @on_active(@id, @password.value)
        )
        @login.index = 2
   
        if DCore.Greeter.is_hide_users()
            @account.focus()
        else
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
        if DCore.Greeter.in_authentication()
            DCore.Greeter.cancel_authentication()
        if DCore.Greeter.is_hide_users()
            DCore.Greeter.start_authentication("*other")
        else
            DCore.Greeter.set_selected_user(@id)
            DCore.Greeter.start_authentication(@id)
    
    blur: ->
        @element.setAttribute("class", "UserInfo")
        @login?.destroy()
        @login = null
        @loading?.destroy()
        @loading = null
        if DCore.Greeter.in_authentication()
            DCore.Greeter.cancel_authentication()
    
    show_login: ->
        if false
            @login()
        else if not @login
            @login = new LoginEntry("login", (u, p)=>@on_verify(u, p))
            @element.appendChild(@login.element)
            @login.password.focus()
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
                        @focus()
                        @login_displayed = false
    
            if @name.innerText == "guest"
                @login.password.style.display="none"
        else
            @focus()

    on_verify: (username, password)->
        @login.destroy()
        @loading = new Loading("loading")
        @element.appendChild(@loading.element)
        #        _session = de_menu.menu.items[de_menu.get_current()][0]
        DCore.Greeter.set_selected_session(de_menu.menu.items[de_menu.get_current()][0])
        if DCore.Greeter.is_hide_users()
            DCore.Greeter.set_selected_user(username)
            DCore.Greeter.login_clicked(username)
        DCore.Greeter.login_clicked(password)

        #debug code begin
        #div_auth = create_element("div", "", $("#Debug"))
        #div_auth.innerText += "authenticate"

        #div_id = create_element("div", "", div_auth)
        #div_id.innerText = @id

        #div_password = create_element("div", "", div_auth)
        #div_password.innerText = password

        #div_session = create_element("div", "", div_auth)
        #div_session.innerText = _session
        #debug code end

# below code should use c-backend to fetch data 
if DCore.Greeter.is_hide_users()
    u = new UserInfo("Hide user", "Hide user", "images/img01.jpg")
    roundabout.appendChild(u.li)
    u.focus()
else
    users = DCore.Greeter.get_users()
    for user in users
        u = new UserInfo(user, user, "images/img01.jpg")
        roundabout.appendChild(u.li)
        if user == DCore.Greeter.get_default_user()
            u.focus()
    if DCore.Greeter.is_support_guest()
        u = new UserInfo("guest", "guest", "images/guest.jpg")
        roundabout.appendChild(u.li)
        if DCore.Greeter.is_guest_default()
            u.focus()

DCore.signal_connect("message", (msg) ->
    echo msg.error
)

DCore.signal_connect("auth", (msg) ->
    user = _current_user
    user.focus()
    user.show_login()
    user.login.password.setAttribute("type", "text")
    user.login.password.style.color = "red"
    user.login.password.value = msg.error
    user.login.password.blur()
    user.login.password.addEventListener("focus", (e)=>
        user.login.password.setAttribute("type", "password")
        user.login.password.style.color ="black"
        user.login.password.value = ""
    )
    apply_refuse_rotate(user.element, 0.5)
)

if roundabout.children.length == 2
    roundabout.style.width = "0"

run_post(->
    l = (screen.width  - roundabout.clientWidth) / 2
    roundabout.style.left = "#{l}px"
)
