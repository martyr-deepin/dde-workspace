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

enable_detection = (enabled)->
    DCore[APP_NAME].enable_detection(enabled)

user_div = null
user_ul = null
message_tip = null
draw_camera_id = null
_current_user = null
userinfo_list = []
_drag_flag = false

#_default_bg_src = "/usr/share/backgrounds/default_background.jpg"
#_current_bg = create_img("Background", _default_bg_src)
#document.body.appendChild(_current_bg)
background = $("#background")
background.width = screen.width
background.height = screen.height


class User extends Widget
    is_livecd = false
    username = null
    userimage = null
    userinfo = null
    _current_user = null

    constructor:->
        super
        @is_livecd()
        user_div = create_element("div","user_div",@element)
        user_ul = create_element("ul","user_ul",user_div)
        @new_switchuser()
        @new_userinfo()

    
    is_livecd:->
        try
            is_livecd = DCore.DBus.sys_object("com.deepin.dde.lock", "/com/deepin/dde/lock", "com.deepin.dde.lock").IsLiveCD_sync(user)
        catch error
            is_livecd = false

    new_switchuser:->
        if not is_livecd
            s = new SwitchUser("switchuser")
            user_ul.appendChild(s.element)
            return s

    new_userinfo:->
        username = lock.get_username()
        userimage = lock.get_userimage()
        userinfo = new UserInfo(username, username, userimage)
        user_ul.appendChild(userinfo.li)
        userinfo.focus()
        if not userinfo.face_login
            userinfo.show_login()

        if user_ul.children.length <= 2
            user_ul.style.width = "0"
            # l = (screen.width  - user_ul.clientWidth) / 2
            # user_ul.style.left = "#{l}px"
            user = Widget.look_up(user_ul.children[0].children[0].getAttribute("id"))
            if not user?.face_login
                user?.show_login()
        return userinfo

    get_current_user:->
        @new_userinfo() if userinfo == null
        _current_user = userinfo
        # if _current_user.face_login
        #     message_tip = new MessageTip(SCANNING_TIP, user_ul.parentElement)
        return _current_user

    import_css:(src)->
        inject_css(@element,src)


class LoginEntry extends Widget
    constructor: (@id, @loginuser, @on_active)->
        super
        if is_hide_users
            @account = create_element("input", "Account", @element)
            @account.setAttribute("autofocus", "true")
            @account.addEventListener("keyup", (e)=>
                if e.which == ENTER_KEY
                    if not @account.value
                        @account.focus()
                    else
                        @password.focus()
            )

        @warning = create_element("div", "CapsWarning", @element)
        @password = create_element("input", "Password", @warning)
        @password.classList.add("PasswordStyle")
        @password.setAttribute("maxlength", 16)

        @check_capslock()

        @password.addEventListener("keyup", (e)=>
            @check_capslock()
            if e.which == ENTER_KEY
                if @check_completeness
                    if is_hide_users
                        @on_active(@account.value, @password.value)
                    else
                        @on_active(@loginuser, @password.value)
        )

        @login = create_element("button", "LoginButton", @element)
        if is_greeter
            @login.innerText = _("Log In")
        else
            @login.innerText = _("Unlock")

        @login.addEventListener("click", =>
            if @check_completeness
                if is_hide_users
                    @on_active(@account.value, @password.value)
                else
                    @on_active(@loginuser, @password.value)
        )
        @element.setAttribute("autofocus", true)

    check_capslock: ->
        if DCore[APP_NAME].detect_capslock()
            @warning.classList.add("CapsWarningBackground")
        else
            @warning.classList.remove("CapsWarningBackground")

    check_completeness: ->
        if is_hide_users
            if not @account.value
                @account.focus()
                return false
        if not @password.value
            @password.focus()
            return false
        return true


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
            clearInterval(draw_camera_id)
            draw_camera_id = null
            DCore.Lock.switch_user()
        )


class UserInfo extends Widget
    constructor: (@id, name, @img_src)->
        super
        @face_login = DCore[APP_NAME].use_face_recognition_login(name)
        # echo "use face login: #{@face_login}"
        @li = create_element("li", "")
        @li.appendChild(@element)

        @userbase = create_element("div", "UserBase", @element)

        if @face_login
            @avatar = create_element("canvas", "UserImg", @userbase)
            @avatar.setAttribute('width', "#{CANVAS_WIDTH}px")
            @avatar.setAttribute('height', "#{CANVAS_HEIGHT}px")
            @draw_avatar()
        else
            @avatar = create_img("UserImg", @img_src, @userbase)

        warp = create_element('div', "UserName", @userbase)

        if @face_login
            @camera_flag = create_img('camera_flag', 'images/camera.png', warp)
            @camera_flag.addEventListener('click', (e)->
                e.preventDefault()
                e.stopPropagation()
            )

            @scanner = create_element('div', 'scanner', @userbase)
            @scan_line = create_img('', 'images/scan-line.png', @scanner)

        @name = create_element("div", "UserName", warp)
        @name.innerText = name

        @element.index = 0
        @index = user_div.childElementCount
        userinfo_list.push(@)

        @login_displayed = false
        @display_failure = false
        @is_recognizing = false
        @session = DCore.Greeter.get_user_session(@id) if is_greeter

    draw_avatar: ->
        ctx = @avatar.getContext("2d")
        img = new Image()
        img.onload = ->
            ctx.drawImage(img, 0, 0)
        img.src = @img_src

    focus: ->
        DCore[APP_NAME].set_username(@id)

        _current_user?.blur()
        _current_user = @
        $("#user_div").focus()
        @element.focus()
        @add_css_class("UserInfoSelected")

        if @id != "guest"
            if is_greeter
                DCore.Greeter.draw_user_background(background, @id)

                if @session? and @session in sessions
                    de_menu.set_current(@session)
                else
                    echo "#{@id} in focus invalid user session"
            else
                DCore.Lock.draw_background(background)

            clearInterval(draw_camera_id)
            draw_camera_id = null
            @draw_camera()
            if @face_login
                enable_detection(true)

    blur: ->
        @element.setAttribute("class", "UserInfo")
        @login?.destroy()
        @login = null
        @loading?.destroy()
        @loading = null
        @login_displayed = false

        if @ != _current_user
            if @face_login
                enable_detection(false)
            clearInterval(draw_camera_id)
            draw_camera_id = null
            _current_user?.stop_animation()
            @draw_avatar()

    show_login: ->
        if @face_login
            enable_detection(false)

        if false
            @login()
        else if _drag_flag
            echo "in drag"

        else if _current_user == @ and not @login
            @login = new LoginEntry("login", @id, (u, p)=>@on_verify(u, p))
            @element.appendChild(@login.element)

            if is_hide_users
                @element.style.paddingBottom = "0px"
                @login.account.focus()
            else
                @login.password.focus()

            if @id == "guest"
                @login.password.style.display = "none"
                @login.password.value = "guest"

            if is_greeter
                if not DCore.Greeter.user_need_password(@id)
                    @login.password.style.display = "none"
                    @login.password.value = "deepin"
            else
                if not DCore.Lock.need_password()
                    @login.password.style.display = "none"
                    @login.password.value = "deepin"

            @login_displayed = true
            @add_css_class("UserInfoSelected")
            @add_css_class("foo")

    hide_login: ->
        if @face_login
            enable_detection(true)

        if @login and @login_displayed
            @blur()
            @focus()

    do_click: (e)=>
        if _current_user == @
            if not @login and not @in_drag
                if @face_login
                    if not @is_recognizing
                        if e.target.className == 'UserImg'
                            message_tip?.remove()
                            DCore[APP_NAME].start_recognize()
                    if e.target.className = "UserName"
                        message_tip?.remove()
                        @show_login()
                        @stop_animation()
                else
                    @show_login()
            else
                if e.target.parentElement.className == "LoginEntry" or e.target.parentElement.className == "CapsWarning"
                    echo "do click:login pwd clicked"
                else
                    @hide_login()

                    if @face_login
                        message_tip?.remove()
                        DCore[APP_NAME].start_recognize()
        else
            @focus()

    on_verify: (username, password)->
        if not password or @display_failure
            @login.password.focus()
            @display_failure = false
        else
            echo 'destroy'
            @login.destroy()
            echo 'destroy end'
            @loading = new Loading("loading")
            @element.appendChild(@loading.element)

            if is_greeter
                session = de_menu.get_current()
                if not session?
                    echo "get session failed"
                    session = "deepin"
                @session = session
                echo 'start session'
                DCore.Greeter.start_session(username, password, @session)
                echo 'start session end'
            else
                DCore.Lock.try_unlock(password)

    hide_user_fail:  (msg) ->
        @login.account.style.color = "red"
        @login.account.value = msg
        @login.account.blur()

        document.body.addEventListener("keydown", (e)=>
            if e.which == ENTER_KEY and @login_displayed and @display_failure
                @login.account.focus()
        )

        @login.account.addEventListener("focus", (e)=>
            @login.account.style.color = "black"
            @login.account.value = ""
            @display_failure = false
        )

    normal_user_fail: (msg) ->
        @login.password.classList.remove("PasswordStyle")
        @login.password.style.color = "red"
        @login.password.value = msg
        @login.password.blur()

        document.body.addEventListener("keydown", (e)=>
            if e.which == ENTER_KEY and is_greeter and @login_displayed and @display_failure
                @login.password.focus()
        )

        @login.password.addEventListener("focus", (e)=>
            @login.password.classList.add("PasswordStyle")
            @login.password.style.color ="black"
            @login.password.value = ""
            @display_failure = false
        )

    auth_failed: (msg) ->
        # echo "[User.auth_failed]"
        if not @login_displayed and @face_login
            # echo "face login failed"
            @stop_animation()
            message_tip?.remove()
            message_tip = null
            message_tip = new MessageTip(msg, user_div.parentElement)
        else
            # echo "login failed"
            @focus()
            @show_login()
            @display_failure = true

            if is_hide_users
                @hide_user_fail(msg)
            else
                @normal_user_fail(msg)

            apply_refuse_rotate(@element, 0.5)

    animate_prev: ->
        if @face_login
            DCore[APP_NAME].cancel_detect()

        if @is_recognizing
            return

        if @index is 0
            prev_index = _counts - 1
        else
            prev_index = @index - 1

        setTimeout( ->
                userinfo_list[prev_index].focus()
                return true
            ,200)
        jQuery("#user_div").user_div("animateToChild", prev_index)

    animate_next: ->
        if @face_login
            DCore[APP_NAME].cancel_detect()

        if @is_recognizing
            return

        if @index is _counts - 1
            next_index = 0
        else
            next_index = @index + 1

        setTimeout( ->
                userinfo_list[next_index].focus()
                return true
            ,200)
        jQuery("#user_div").user_div("animateToChild", next_index)

    animate_near: ->
        if @face_login
            DCore[APP_NAME].cancel_detect()

        if @is_recognizing
            return

        try
            near_index = jQuery("#user_div").user_div("getNearestChild")
        catch error
            echo "getNeareastChild error"

        if near_index is false
            near_index = @index

        setTimeout( ->
                userinfo_list[near_index].focus()
                _drag_flag = false
                return true
            ,200)
        jQuery("#user_div").user_div("animateToChild", near_index)

    draw_camera: ->
        if @face_login
            clearInterval(draw_camera_id)
            draw_camera_id = setInterval(=>
                DCore[APP_NAME].draw_camera(@avatar, @avatar.width, @avatar.height)
            , 20)

    start_animation: =>
        # echo '[start_animation]'
        if @face_login
            # echo '[set animation]'
            @scanner.style.display = 'block'
            @scanner.style.zIndex = 300
            @scanner.style.webkitAnimation = "scanning #{ANIMATION_TIME}s linear infinite"
            @scan_line.style.display = 'block'

    stop_animation: ->
        # echo '[stop_animation]'
        if @face_login
            @scanner.style.display = 'none'
            @scanner.style.zIndex = -300
            @scanner.style.webkitAnimation = ''
            @scan_line.style.display = 'none'

DCore.signal_connect("draw", ->
    # echo 'receive draw signal'
    clearInterval(draw_camera_id)
    draw_camera_id = null
    _current_user.draw_camera()
)

DCore.signal_connect("start-animation", ->
    # echo "receive start animation"
    _current_user.is_recognizing = true
    _current_user.hide_login()
    _remove_click_event?()
    _current_user.start_animation()
)

DCore.signal_connect("auth-failed", (msg)->
    # echo "[auth-failed]"
    _current_user.is_recognizing = false
    _current_user.auth_failed(msg.error)
)

DCore.signal_connect("failed-too-much", (msg)->
    # echo '[failed-too-much]'
    _current_user.is_recognizing = false
    _current_user.auth_failed(msg.error)
    _current_user.show_login()
    message_tip.adjust_show_login()
)

