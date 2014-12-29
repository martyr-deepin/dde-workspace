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

draw_camera_id = null
_current_user = null
password_error_msg = null

class User extends Widget
    img_src_before = "images/userswitch/"
    constructor:(@id,@parent)->
        super
        inject_css(_b,"css/user.css")
        @parent?.appendChild(@element)
        @user_session = []
        @userinfo_all = []
        if accounts.get_dbus_failed then new NoAccountServiceMessage()
        @get_default_userid()

    get_default_userid:->
        @_default_username = accounts.get_default_username()
        console.log "_default_username:#{@_default_username}"
        if @_default_username is null or @_default_username == guest.Name then @_default_username = accounts.users_name[0]
        @_default_userid = accounts.get_user_id(@_default_username)
        echo "_default_username:#{@_default_username};uid:#{@_default_userid}"
        return @_default_userid

    sort_current_user_info_center:->
        echo "sort_current_user_info_center"
        tmp_length = (@userinfo_all.length - 1) / 2
        center_index = Math.round(tmp_length)
        if _current_user.index != center_index
            center_old = @userinfo_all[center_index]
            @userinfo_all[center_index] = _current_user
            @userinfo_all[_current_user.index] = center_old
            _current_user.index = center_index

     isSupportGuest:->
        if is_support_guest and accounts.isAllowGuest() is true
            u = new UserInfo(guest.Uid, guest.UserName, guest.IconFile)
            @userinfo_all.push(u)
            #if DCore.Greeter.is_guest_default() then u.show()
            #else u.hide()

    new_userinfo_for_greeter:->
        echo "new_userinfo_for_greeter"
        for uid in accounts.users_id
            if not accounts.is_disable_user(uid)
                username = accounts.users_id_dbus[uid].UserName
                usericon = accounts.users_id_dbus[uid].IconFile
                u = new UserInfo(uid, username, usericon)
                @userinfo_all.push(u)
                u.is_logined = accounts.is_user_sessioned_on(uid)
                _current_user = u if uid is @_default_userid
        @isSupportGuest()

        user.index = j for user,j in @userinfo_all
        if not _current_user?
            _current_user = @userinfo_all[0]
            _current_user.index = 0
        for user in @userinfo_all
            @element.appendChild(user.element)
            if user.index is _current_user.index
                _current_user.show()
                _current_user.get_session_by_lightdm()
                _current_user.update_session_icon()
            else
                user.hide()
        return @userinfo_all

    new_userinfo_for_lock:->
        echo "new_userinfo_for_lock"
        if DCore.Lock.is_guest()
            _current_user = new UserInfo(guest.Uid, guest.UserName, guest.IconFile)
        else
            username = accounts.users_id_dbus[@_default_userid].UserName
            usericon = accounts.users_id_dbus[@_default_userid].IconFile
            _current_user = new UserInfo(@_default_userid, username, usericon)
        _current_user.index = 0
        @element.appendChild(_current_user.element)
        _current_user.show()

    get_current_userinfo:->
        return _current_user

    set_current_userinfo: (uid)->
        if _current_user.id is uid then return
        _current_user = user for user in @userinfo_all when user.id is uid

    check_index:(index)->
        if index > @userinfo_all.length - 1 then index = 0
        else if index < 0 then index = @userinfo_all.length - 1
        return index

    switch_to_userinfo :(uid) =>
        if _current_user.id is uid then return
        _current_user.hide_animation()
        _current_user = user for user in @userinfo_all when user.id is uid
        echo "switch_to_userinfo:#{_current_user.username} === #{_current_user.id}"
        _current_user.show_animation()

    switch_userinfo :(direc) =>
        if @userinfo_all.length < 2 then return
        if !_current_user.animation_end then return
        echo "switch_userinfo ---#{direc}--- from #{_current_user.index}: #{_current_user.username}"
        _current_user.hide_animation()
        if direc is "prev" then index = _current_user.index - 1
        else if direc is "next" then index = _current_user.index + 1
        index = @check_index(index)
        _current_user = @userinfo_all[index]
        echo "to #{_current_user.index}: #{_current_user.username}"
        _current_user.update_session_icon()
        _current_user.show_animation()
        _current_user.animate_prev()


class UserInfo extends Widget
    constructor: (@id, @username, @usericon)->
        super
        echo "new UserInfo :#{@username}"
        @session = "deepin"
        @is_logined = false
        @is_recognizing = false
        @animation_end = true
        @index = null
        @time_animation = 500
        @face_login = @userFaceLogin(@username)
        @userinfo_build()


    userinfo_build:->
        @userbase = create_element("div", "UserBase", @element)
        @face_recognize_div = create_element("div","face_recognize_div",@userbase)
        #@face_recognize_border = create_img("face_recognize_div","images/userinfo/facelogin_boder.png",@face_recognize_div)
        @face_recognize_img = create_img("face_recognize_img","images/userinfo/facelogin_animation.png",@face_recognize_div)
        @userimg_div = create_element("div","userimg_div",@face_recognize_div)
        @userimg_border = create_element("div","userimg_border",@userimg_div)
        @userimg_background = create_element("div","userimg_background",@userimg_border)
        @userimg = create_img("userimg", @usericon, @userimg_background)
        @userimg_div.style.display = "none"
        @username_div = create_element("div", "username_div", @userbase)
        @username_div.innerText = @username
        @username_div.style.display = "none"
        @login = new LoginEntry("login", @username, (u, p)=>@on_verify(u, p))
        @element.appendChild(@login.element)
        @login.hide()

        @face_recognize_div.style.display = "block"
        @face_recognize_img.style.display = "none"

    hide:=>
        @username_div.style.display = "none"
        @login.hide()
        @userimg_div.style.display = "none"
        @element.style.display = "none"
        @blur()

    show:=>
        @userimg_div.style.display = "-webkit-box"
        @username_div.style.display = "block"
        @login.show()
        @element.style.display = "-webkit-box"
        @userimg.style.opacity = "1.0"
        @focus()

    hide_animation:(cb)->
        @username_div.style.display = "none"
        @login.hide()
        @userimg.style.opacity = "1.0"
        @animation_end = false
        jQuery(@userimg).animate({opacity:'0.0'},@time_animation,
            "linear",=>
                @userimg_div.style.display = "none"
                @element.style.display = "none"
                @blur()
                @animation_end = true
                cb?()
        )

    show_animation:(cb)->
        @show()
        @userimg.style.opacity = "0.0"
        @animation_end = false
        jQuery(@userimg).animate({opacity:'1.0'},@time_animation,
            "linear",=>
                @animation_end = true
                cb?()
        )

    userFaceLogin: (name)->
        return false

    draw_camera: ->
        if !@face_login then return
        clearInterval(draw_camera_id)
        draw_camera_id = setInterval(=>
            DCore[APP_NAME].draw_camera(@userimg, @userimg.width, @userimg.height)
        , 20)

    loginAnimation: ->
        echo "loginAnimation"
        rotate = 0
        rotate_animation = =>
            @face_recognize_img.style.display = "block"
            @face_animation_interval = setInterval(=>
                rotate = (rotate + 10 * scaleFinal) % 360
                animation_rotate(@face_recognize_img,rotate)
            ,20)
        @auth_time = 500#test is 85
        @auth_timeout = setTimeout(rotate_animation,@auth_time)

    loginAnimationClear: ->
        echo "loginAnimationClear"
        @face_recognize_img.style.display = "none"
        clearTimeout(@auth_timeout) if @auth_timeout
        clearInterval(@face_animation_interval) if @face_animation_interval

    draw_avatar: ->
        if !@face_login then return
        @loginAnimation()
        enable_detection(true)

    stop_avatar:->
        if !@face_login then return
        clearInterval(draw_camera_id)
        draw_camera_id = null
        @loginAnimationClear()
        enable_detection(false)
        DCore[APP_NAME].cancel_detect()

    get_session_by_lightdm:->
        @session = "deepin"
        try
            @session = DCore.Greeter.get_user_session(@username)
            echo "Greeter.get_user_session(#{@username}):#{@session}"
            sessions = DCore.Greeter.get_sessions()
            if @session? and @session in sessions
                echo "#{@username} session is #{@session} "
            else
                if "deepin" in sessions
                    @session = "deepin"
                    echo "session default_session deepin--"
                else
                    @session = sessions[0]
                    echo "session set #{sessions[0]}--"
            return @session
        catch e
            echo "#{e}"
            return @session

    update_session_icon: ->
        if @is_logined
            desktopmenu?.hide()
        else
            if not @session? then @get_session_by_lightdm()
            echo "userinfo #{@username} update_session_icon:#{@session}"
            desktopmenu?.update_current_icon(@session)
        localStorage.setItem("menu_current_id_desktop",@session)

    focus:->
        echo "#{@username} focus"
        @login.password?.focus() if @username isnt guest.UserName

        if @face_login
            DCore[APP_NAME].set_username(@username)
            @draw_camera()
            @draw_avatar()
        _current_user = @
        localStorage.setItem("_current_user",_current_user)

    blur: ->
        @loginAnimationClear()
        @stop_avatar()

    on_verify: (username, password)->
        echo "on_verify:#{username}"
        if username is guest.UserName then username = guest.Name
        @password = password
        if is_greeter
            @loginAnimation()
            @session = localStorage.getItem("menu_current_id_desktop")
            if @session is null or @session is undefined then @get_session_by_lightdm()
            echo "#{username} start session #{@session}"
            DCore.Greeter.start_session(username, password, @session)
            document.body.cursor = "wait"
        else
            echo "#{username} try_unlock "
            @loginAnimation()
            DCore.Lock.try_unlock(username,password)

    auth_failed: (msg) =>
        @loginAnimationClear()
        @stop_avatar()
        @login.password_error(msg)

    animate_prev: ->
        if @face_login
            DCore[APP_NAME].cancel_detect()

    animate_next: ->
        if @face_login
            DCore[APP_NAME].cancel_detect()

class LoginEntry extends Widget
    img_src_before = "images/userinfo/"
    constructor: (@id, @username,@on_active)->
        super
        if is_greeter then @id = "login"
        else @id = "lock"
        echo "new LoginEntry:#{@id}"

        @is_need_pwd = accounts?.is_need_pwd(accounts.get_user_id(@username))
        echo "#{@id} , #{@username} is_need_pwd is #{@is_need_pwd}"

        if @is_need_pwd
            @password_create()
            @keyboard_img_create()
        @loginbutton_create()

    check_capslock: ->
        if DCore[APP_NAME].detect_capslock()
            @caps.style.display = "block"
        else
            @caps.style.display = "none"

    password_create: ->
        @password_div = create_element("div", "password_div", @element)
        @password = create_element("input", "password", @password_div)
        @caps = create_element("div", "CapsWarning", @password_div)
        @password.type = "password"
        @password.setAttribute("autofocus", true) if @username isnt guest.UserName
        @password_eventlistener()

    keyboard_img_create: ->
        if !is_greeter then @keyboard_dbus = new Keyboard()
        if is_greeter then @layouts = DCore.Greeter.get_user_layouts(@username)
        else @layouts = @keyboard_dbus.updateUserLayoutList()
        if @layouts?.length < 2 then return
        echo "user_layouts---#{@username}----========="
        echo @layouts

        @keyboard_img = create_element("div","keyboard_img",@password_div)
        @keyboard_img.style.position = "absolute"
        @keyboard_img.style.left = 10
        @keyboard_img.style.bottom = "2em"
        @password?.style.paddingLeft = 10 + 30
        @keyboard_create()
        @keyboard_img.addEventListener("click",(e)=>
            e.stopPropagation()
            @keyboard?.toggle()
        )

    keyboard_create: ->
        @keyboard = new Select("keyboard_#{@username}",div_keyboard)
        @keyboard.element.style.position = "absolute"
        @keyboard.element.style.left = -5
        @keyboard.element.style.top = -20
        @get_current_layout()
        #@check_layouts_is_in_lightdm()
        @keyboard.set_lists(@current_layout,@layouts)
        @keyboard.boxscroll_create()
        @keyboard.set_cb( (selected)=>
            @selected = selected
            echo "keyboard layout selected:#{@selected}"
            if is_greeter then DCore.Greeter.set_layout(selected)
            else @keyboard_dbus?.setCurrentLayout(selected)
            @keyboard?.hide()
        )
        document.body.addEventListener("click",(e)=>
            e.stopPropagation()
            @keyboard?.hide()
        )
    get_current_layout: ->
        if is_greeter then @current_layout = DCore.Greeter.get_current_layout()
        else @current_layout = @keyboard_dbus?.getCurrentLayout()

    check_layouts_is_in_lightdm: ->
        if !is_greeter then return
        @layouts_lightdm = DCore.Greeter.lightdm_get_layouts_des()
        for lay in @layouts
            if lay in @layouts_lightdm
                echo "#{lay}============ layouts from ini is in layouts_lightdm"
            else
                echo "#{lay}============ layouts from ini is not!!! in layouts_lightdm"

    loginbutton_create: ->
        if @is_need_pwd
            @loginbutton = create_img("loginbutton", "#{img_src_before}#{@id}_normal.png",@password_div)
            @loginbutton.type = "button"
            @loginbutton.style.position = "relative"
            @loginbutton.style.right = "3.15em"
            @loginbutton.style.bottom = "0.2em"
        else
            @loginbutton = create_element("div","loginbutton_unpwd",@element)
            @loginbutton.type = "button"
            if @id == "login"
                @loginbutton.innerText = _("Login")
            else if @id == "lock"
                @loginbutton.innerText = _("Unlock")
            @element.style.marginTop = "0.6em"
        @loginbutton.addEventListener("mouseout", =>
            power_flag = false
            if (power = localStorage.getObject("shutdown_from_lock"))?
                if power.lock is true
                    power_flag = true
            if power_flag
                @loginbutton.src = "#{img_src_before}#{power.value}_normal.png"
            else
                @loginbutton.src = "#{img_src_before}#{@id}_normal.png"
        )
        @loginbutton_eventlistener()

    show:->
        @element.style.display = "-webkit-box"
        @password?.focus()

    hide:->
        @element.style.display = "none"
        @password?.blur()
        @keyboard?.hide()

    password_eventlistener:->
        @password?.addEventListener("click", (e)=>
            e.stopPropagation()
            @keyboard?.hide()
            if @username is guest.UserName then return
            if @password.value is password_error_msg or @password.value is localStorage.getItem("password_value_shutdown")
                @input_password_again()
        )
        @password?.addEventListener("blur",=>
            @check_capslock()
            @keyboard?.hide()
        )
        @password?.addEventListener("focus",=>
            @check_capslock()
            if @username is guest.UserName then return
            if @password.value is password_error_msg or @password.value is localStorage.getItem("password_value_shutdown")
                @input_password_again()
        )
        @password?.addEventListener("keyup",(e)=>
            @check_capslock()
            if @username is guest.UserName then return
            if e.which == ENTER_KEY
                @on_active(@username, @password.value) if @check_completeness()
        )
        document.body.addEventListener("keydown",(e)=>
            try
                els = $(".MenuChoose")
                focus = true
                for el in els
                    if el.style.display isnt "none" then focus = false
                @password?.focus() if focus
            catch e
                echo "#{e}"
        )


    loginbutton_eventlistener: ->
        @loginbutton.addEventListener("click", =>
            echo "loginbutton click"
            power_flag = false
            if (power = localStorage.getObject("shutdown_from_lock"))?
                if power.lock is true
                    power_flag = true
            if power_flag
                @loginbutton.src = "#{img_src_before}#{power.value}_press.png"
            else
                @loginbutton.src = "#{img_src_before}#{@id}_press.png"
            if @check_completeness
                value = null
                if @is_need_pwd then value = @password?.value
                else value = ""
                @on_active(@username, value)
        )

    check_completeness: ->
        if !@is_need_pwd then return true
        if is_livecd then return true
        else if not @password?.value
            @password?.focus()
            return false
        else if @password?.value is password_error_msg or @password?.value is localStorage.getItem("password_value_shutdown")
            @input_password_again()
            return false
        return true

    input_password_again:->
        @password?.style.color = "rgba(255,255,255,0.5)"
        @password?.style.fontSize = "2.0em"
        @password?.style.paddingBottom = "0.2em"
        @password?.style.letterSpacing = "5px"
        @password?.type = "password"
        @password?.focus()
        @loginbutton.disable = false
        @password?.value = null

    password_error:(msg)->
        @password?.style.color = "#F4AF53"
        @password?.style.fontSize = "1.5em"
        @password?.style.paddingBottom = "0.4em"
        @password?.style.letterSpacing = "0px"
        @password?.type = "text"
        password_error_msg = msg
        @password?.value = password_error_msg
        @password?.blur()
        @loginbutton.disable = true




DCore.signal_connect("draw", ->
    echo 'receive camera draw signal'
    clearInterval(draw_camera_id)
    draw_camera_id = null
    _current_user.draw_camera()
)

DCore.signal_connect("start-animation", ->
    echo "receive ,start animation"
    _current_user.is_recognizing = true
    _remove_click_event?()
    _current_user.draw_avatar()
)

DCore.signal_connect("auth-failed", (msg)->
    echo "#{_current_user.username}:[auth-failed]"
    _current_user.is_recognizing = false
    _current_user.auth_failed(msg.error)
)

DCore.signal_connect("failed-too-much", (msg)->
    echo '[failed-too-much]'
    _current_user.is_recognizing = false
    _current_user.auth_failed(msg.error)
)

DCore.signal_connect("auth-succeed", ->
    echo "auth-succeed!"
    if is_greeter
        echo "greeter exit"
    else
        if powermenu?.check_is_shutdown_from_lock()
            powermenu?.auth_succeed_excute()
        else
            enableZoneDetect(true)
            DCore.Lock.quit()
            echo "dlock exit"
)

