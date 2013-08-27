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

class Tip
    constructor:(@parent)->
        @failed_tip = null
        @failed_tip = create_element("div", "failed-tip", parent)
        @failed_tip.appendChild(document.createTextNode(LOGIN_FAILED_TIP_TEXT))

    remove: =>
        if @failed_tip
            @parent.removeChild(@failed_tip)
            @failed_tip = null

failed_tip = null

apply_refuse_rotate = (el, time)->
    apply_animation(el, "refuse", "#{time}s", "linear")
    setTimeout(->
        el.style.webkitAnimation = ""
    , time * 1000)

class LoginEntry extends Widget
    constructor: (@id, @on_active)->
        super
        @warning = create_element("div", "CapsWarning", @element)
        @password = create_element("input", "Password", @warning)
        @password.classList.add("PasswordStyle")
        @password.setAttribute("maxlength", 16)
        @password.setAttribute("autofocus", true)

        if DCore.Lock.detect_capslock()
            @warning.classList.add("CapsWarningBackground")
        else
            @warning.classList.remove("CapsWarningBackground")

        @password.addEventListener("keyup", (e)=>
            if DCore.Lock.detect_capslock()
                @warning.classList.add("CapsWarningBackground")
            else
                @warning.classList.remove("CapsWarningBackground")

            if e.which == ENTER_KEY
                @on_active(@password.value)
        )

        @login = create_element("button", "LoginButton", @element)
        @login.innerText = _("Unlock")
        @login.addEventListener("click", =>
            @on_active(@password.value)
        )

        @password.index = 0
        @login.index = 1
        @password.focus()

class Loading extends Widget
    constructor: (@id)->
        super
        create_element("div", "ball", @element)
        create_element("div", "ball1", @element)
        create_element("span", "", @element).innerText = _("Welcome")

class SwitchUser extends Widget
    constructor: (@id)->
        super
        @switch = create_element("div", "SwitchGreeter", @element)
        @switch.innerText = _("Switch User")
        @switch.addEventListener("click", =>
            failed_tip?.remove()
            DCore.Lock.switch_user()
        )

_current_user = null

class UserInfo extends Widget
    constructor: (@id, name, img_src)->
        super
        @li = create_element("li", "")
        @li.appendChild(@element)
        @userbase = create_element("div", "UserBase", @element)
        if img_src
            @img = create_img("UserImg", img_src, @userbase)
        else
            @canvas = create_element("canvas", "UserImg", @userbase)
            @canvas.setAttribute('width', "#{CANVAS_WIDTH}px")
            @canvas.setAttribute('height', "#{CANVAS_HEIGHT}px")
            @camera_flag = create_img('camera', 'images/camera.png', @userbase)

            @scanner = create_element('div', 'scanner', @userbase)
            @scan_line = create_img('', 'images/scan-line.png', @scanner)
        @name = create_element("div", "UserName", @userbase)
        @name.innerText = name
        @login_displayed = false
        @display_failure = false

    start_animation: ->
        if @canvas?
            @scanner.style.zIndex = 100
            @scanner.style.webkitAnimation = 'scanning 5s linear infinite'
            # @element.removeEventListener("click", click_handler)
            # document.body.removeEventListener("keydown", account_keydown_handler)
            # document.body.removeEventListener("keydown", passwd_keydown_handler)

    stop_animation: ->
        if @canvas?
            @scanner.style.zIndex = -100
            @scanner.style.webkitAnimation = ''
            # @element.addEventListener("click", click_handler)
            # document.body.addEventListener("keydown", account_keydown_handler)
            # document.body.addEventListener("keydown", passwd_keydown_handler)

    draw_camera:->
        if @canvas?
            echo 'draw camera'
            setInterval(=>
                DCore.Lock.draw_camera(@canvas, @canvas.width, @canvas.height)
            , 20)

    focus: ->
        _current_user?.blur()
        _current_user = @
        @element.focus()
        @add_css_class("UserInfoSelected")

    blur: ->
        @element.setAttribute("class", "UserInfo")
        @login?.destroy()
        @login = null
        @loading?.destroy()
        @loading = null
        @login_displayed = false

    show_login: ->
        if false
            @login()
        else if not @login
            @login = new LoginEntry("login", (p)=>@on_verify(p))
            @element.appendChild(@login.element)

            if DCore.Lock.need_pwd()
                @login.password.focus()
            else
                @login.password.style.display = "none"
                @login.password.value = "deepin"
            @login_displayed = true
            @add_css_class("foo")

    hide_login: ->
        if @login and @login_displayed
            @blur()
            @focus()

    do_click: (e)->
        if _current_user == @
            if not @login
                if @canvas
                    if e.target.className == "UserName"
                        failed_tip?.remove()
                        @show_login()
                else
                    @show_login()
            else
                if e.target.parentElement.className == "LoginEntry" or e.target.parentElement.className == "CapsWarning"
                    echo "login pwd clicked"
                else
                    if @canvas
                        if e.target.className == "UserName"
                            failed_tip?.remove()
                            @hide_login()
                    else
                        @hide_login()
        else
            @focus()

    on_verify: (password)->
        if not password or @display_failure
            @login.password.focus()
            @display_failure = false
        else
            @login.destroy()
            @loading = new Loading("loading")
            @element.appendChild(@loading.element)
            DCore.Lock.try_unlock(@id, password)

    unlock_check: (msg) ->
        if msg.status == "succeed"
            @display_failure = false
            DCore.Lock.unlock_succeed()
        else
            @focus()
            @show_login()
            @display_failure = true
            @login.password.classList.remove("PasswordStyle")
            @login.password.style.color = "red"
            @login.password.value = msg.status
            @login.password.blur()
            @login.password.addEventListener("focus", (e)=>
                @login.password.classList.add("PasswordStyle")
                @login.password.style.color ="black"
                @login.password.value = ""
                @display_failure = false
            )

            apply_refuse_rotate(@element, 0.5)

user = DCore.Lock.get_username()

user_path = DCore.DBus.sys_object("org.freedesktop.Accounts","/org/freedesktop/Accounts","org.freedesktop.Accounts").FindUserByName_sync(user)
#user_image = DCore.DBus.sys_object("org.freedesktop.Accounts", user_path, "org.freedesktop.Accounts.User").IconFile
user_image = DCore.Lock.get_icon()

if not user_image? or user_image == "nonexists"
    try
        user_image = DCore.DBus.sys_object("com.deepin.passwdservice", "/", "com.deepin.passwdservice").get_user_fake_icon_sync(user)
    catch error
        user_image = "images/img01.jpg"

background.width = screen.width
background.height = screen.height
DCore.Lock.draw_background(background)

$("#Version").innerHTML = "
            <span> #{_("Linux Deepin 12.12")}<sup>#{_(VERSION)}</sup></span>
            "
try
    is_livecd = DCore.DBus.sys_object("com.deepin.dde.lock", "/com/deepin/dde/lock", "com.deepin.dde.lock").IsLiveCD_sync(user)
catch error
    is_livecd = false

if not is_livecd
    s = new SwitchUser("switchuser")
    $("#bottom_buttons").appendChild(s.element)

face_login = DCore.Lock.use_face_recognition_login(user)
echo "face_login: #{face_login}"

u = new UserInfo(user, user, if face_login then null else user_image)
roundabout.appendChild(u.li)
_current_user = u

u.focus()
if not face_login
    u.show_login()

document.body.addEventListener("keydown", (e) =>
    if e.which == ENTER_KEY
        failed_tip?.remove()
        if not u.login_displayed
            u.show_login()
        else
            u.login.on_active(u.login.password.value)

    else if e.which == ESC_KEY
        failed_tip?.remove()
        u.hide_login()
)

DCore.signal_connect("unlock", (msg)->
    u.unlock_check(msg)
)

DCore.signal_connect("draw", ->
    u.draw_camera()
)

DCore.signal_connect("start-animation", ->
    echo "start animation"
    u.start_animation()
)

DCore.signal_connect("login-failed", ->
    echo "stop animation"
    u.stop_animation()
    failed_tip = new Tip(roundabout.parentElement)
)

DCore.signal_connect("start-login", ->
    echo "start login"
    # TODO: maybe some animation or some reflection.
    DCore.Lock.try_unlock(u.id, "")
)

if roundabout.children.length <= 2
    roundabout.style.width = "0"
    l = (screen.width  - roundabout.clientWidth) / 2
    roundabout.style.left = "#{l}px"
    if not face_login
        Widget.look_up(roundabout.children[0].children[0].getAttribute("id"))?.show_login()

DCore.Lock.webview_ok(u.id)
