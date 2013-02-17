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
            @account.addEventListener("keyup", (e)=>
                if e.which == 13
                    if not @account.value
                        @account.focus()
                    else
                        @password.focus()
            )
            @account.index = 0

        @password = create_element("input", "Password", @element)
        @password.setAttribute("type", "password")
        @password.index = 1

        #@password.addEventListener("keydonw", (e)=>
        #    is_shift = e.shiftKey || (e.which == 16) || false
        #    if e.which >= 65 and e.which <= 90 and not is_shift
        #        pass
        #    else if e.which >=97 and e.which <= 122 and is_shift
        #        pass
        #    else
        #        pass

        @password.addEventListener("keyup", (e)=>
            if e.which == 13
                if DCore.Greeter.is_hide_users()
                    if not @account.value
                        @account.focus()
                    else if not @password.value
                        @password.focus()
                    else
                        @on_active(@account.value, @password.value)
                else
                    if not @password.value
                        @password.focus()
                    else
                        @on_active(@id, @password.value)
        )

        @login = create_element("button", "LoginButton", @element)
        @login.innerText = _("Log In")
        @login.addEventListener("click", =>
            if DCore.Greeter.is_hide_users()
                if not @account.value
                    @account.focus()
                else if not @password.value
                    @password.focus()
                else
                    @on_active(@account.value, @password.value)
            else
                if not @password.value
                    @password.focus()
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
        create_element("span", "", @element).innerText = _("Welcome")

_default_bg_src = "/usr/share/backgrounds/1440x900.jpg"
_current_bg = create_img("Background", _default_bg_src)
document.body.appendChild(_current_bg)

_current_user = null
class UserInfo extends Widget
    constructor: (@id, name, img_src)->
        super
        @li = create_element("li", "")
        @li.appendChild(@element)
        @img = create_img("UserImg", img_src, @element)
        @name = create_element("div", "UserName", @element)
        @name.innerText = name
        @active = false
        @login_displayed = false

        if @id == "guest"
            user_bg = _default_bg_src
        else
            try
                user_bg = DCore.Greeter.get_user_background(@id)
            catch error
                user_bg = _default_bg_src

        if user_bg == "nonexists"
            user_bg = _default_bg_src
        @background = create_img("Background", user_bg)

    focus: ->
        _current_user?.blur()
        _current_user = @
        @add_css_class("UserInfoSelected")

        if DCore.Greeter.in_authentication()
            DCore.Greeter.cancel_authentication()

        if DCore.Greeter.is_hide_users()
            DCore.Greeter.start_authentication("*other")
        else
            if @background.src != _current_bg.src
                document.body.appendChild(@background)
                document.body.removeChild(_current_bg)
                _current_bg = @background

            DCore.Greeter.set_selected_user(@id)
            if @id != "guest"
                session = DCore.Greeter.get_user_session(@id)
                if session?
                    if session != "nonexists"
                        de_menu.set_current(session)
                        DCore.Greeter.set_selected_session(session)

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
            if DCore.Greeter.is_hide_users()
                @element.style.paddingBottom = "0px"
                @login.account.focus()
            else
                @login.password.focus()
            @login_displayed = true
            @add_css_class("foo")

    do_click: (e)->
        if _current_user == @
            if not @login
                @show_login()
            else
                if e.target.parentElement.className == @login.element.className
                    echo "login pwd clicked"
                else
                    if @login_displayed
                        @focus()
                        @login_displayed = false

            if @name.innerText == "guest"
                @login.password.style.display="none"
                @login.password.value = "guest"
        else
            @focus()

    on_verify: (username, password)->
        @login.destroy()
        @loading = new Loading("loading")
        @element.appendChild(@loading.element)

        DCore.Greeter.set_selected_session(de_menu.get_useable_current()[0])
        if DCore.Greeter.is_hide_users()
            DCore.Greeter.set_selected_user(username)
            DCore.Greeter.login_clicked(username)
            DCore.signal_connect("prompt", (msg)->
                DCore.Greeter.login_clicked(password)
            )
        else
            DCore.Greeter.login_clicked(password)
        #debug code begin
        #div_auth = create_element("div", "", $("#Debug"))
        #div_auth.innerText += "authenticate"

        #div_id = create_element("div", "", div_auth)
        #div_id.innerText = username

        #div_password = create_element("div", "", div_auth)
        #div_password.innerText = password

        #div_session = create_element("div", "", div_auth)
        #div_session.innerText = de_menu.get_useable_current()[0]
        #debug code end

# below code should use c-backend to fetch data
if DCore.Greeter.is_hide_users()
    u = new UserInfo("*other", "", "images/huser.jpg")
    roundabout.appendChild(u.li)
    Widget.look_up("*other").element.style.paddingBottom = "5px"
    u.focus()
else
    users = DCore.Greeter.get_users()
    echo users
    for user in users
        if user == DCore.Greeter.get_default_user()
            try
                user_image = DCore.Greeter.get_user_image(user)
            catch error
                echo "get user image failed"
            if not user_image? or user_image == "nonexists"
                try
                    user_image = DCore.DBus.sys_object("com.deepin.passwdservice", "/", "com.deepin.passwdservice").get_user_fake_icon_sync(user)
                catch error
                    user_image = "images/guest.jpg"
    
            u = new UserInfo(user, user, user_image) 
            roundabout.appendChild(u.li)
            u.focus()

    if DCore.Greeter.is_support_guest()
        u = new UserInfo("guest", "guest", "images/guest.jpg")
        roundabout.appendChild(u.li)
        if DCore.Greeter.is_guest_default()
            u.focus()

    for user in users
        if user == DCore.Greeter.get_default_user()
            echo "already append default user"
        else
            try
                user_image = DCore.Greeter.get_user_image(user)
            catch error
                echo "get user image failed"
            if not user_image? or user_image == "nonexists"
                try
                    user_image = DCore.DBus.sys_object("com.deepin.passwdservice", "/", "com.deepin.passwdservice").get_user_fake_icon_sync(user)
                catch error
                    user_image = "images/guest.jpg"

            u = new UserInfo(user, user, user_image) 
            roundabout.appendChild(u.li)

DCore.signal_connect("message", (msg) ->
    echo msg.error
)

DCore.signal_connect("auth", (msg) ->
    user = _current_user
    user.focus()
    user.show_login()
    if DCore.Greeter.is_hide_users()
        user.login.account.style.color = "red"
        user.login.account.value = msg.error
        user.login.account.blur()
        if DCore.Greeter.in_authentication()
            DCore.Greeter.cancel_authentication()
        user.login.account.addEventListener("focus", (e)=>
            user.login.account.style.color = "black"
            user.login.account.value = ""
            DCore.Greeter.start_authentication("*other")
        )
    else
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

if roundabout.children.length <= 2
    roundabout.style.width = "0"

run_post(->
    l = (screen.width  - roundabout.clientWidth) / 2
    roundabout.style.left = "#{l}px"
)
