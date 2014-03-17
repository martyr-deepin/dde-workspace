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

user_ul = null
message_tip = null
draw_camera_id = null
_current_user = null
_drag_flag = false
password_error_msg = null

class User extends Widget
    ACCOUNTS_DAEMON = "com.deepin.daemon.Accounts"
    ACCOUNTS_USER =
        obj: ACCOUNTS_DAEMON
        path: "/com/deepin/daemon/Accounts/User1000"
        interface: "com.deepin.daemon.Accounts.User"
    
    GRAPHIC = "com.deepin.api.Graphic"

    img_src_before = null

    username = null
    userimage = null
    userinfo = null
    userinfo_all = []
    userinfo_show_index = 0
        
    time_animation = 1800
    
    constructor:->
        super
        img_src_before = "images/userswitch/"
        user_ul = create_element("ul","user_ul",@element)
        user_ul.id = "user_ul"
        
        @users_dbus = []
        @users_name = []
        @users_id = []
        @users_id_dbus = []
        @users_name_dbus = []
    
        @getDBus()

    getDBus:->
        try
            @Dbus_Account = DCore.DBus.sys(ACCOUNTS_DAEMON)
            for path in @Dbus_Account.UserList
                ACCOUNTS_USER.path = path
                user_dbus = DCore.DBus.sys_object(
                    ACCOUNTS_USER.obj,
                    ACCOUNTS_USER.path,
                    ACCOUNTS_USER.interface
                )
                @users_dbus.push(user_dbus)
                @users_id.push(user_dbus.Uid)
                @users_id_dbus[user_dbus.Uid] = user_dbus
                @users_name_dbus[user_dbus.UserName] = user_dbus
        catch e
            echo "Dbus_Account #{ACCOUNTS_DAEMON} ERROR: #{e}"

        try
            @Dbus_Graphic = DCore.DBus.session(GRAPHIC)
        catch e
            echo "#{GRAPHIC} dbus ERROR: #{e}"


    normal_hover_click_cb: (el,normal,hover,click,click_cb) ->
        el.addEventListener("mouseover",->
            el.src = hover
            el.style.opacity = "0.8"
        ) if hover
        el.addEventListener("mouseout",->
            el.src = normal
        ) if normal
        el.addEventListener("click",=>
            el.style.opacity = "0.8"
            el.src = click
            click_cb?()
        ) if click
    

    get_all_users:->
#        if is_greeter
            #@users_name = DCore.Greeter.get_users()
        #else
        for dbus in @users_dbus
            @users_name.push(dbus.UserName)
        return @users_name

    get_default_username:->
        if is_greeter
            @_default_username = DCore.Greeter.get_default_user()
        else
            @_default_username = DCore.Lock.get_username()
        return @_default_username

    get_user_image:(user) ->
        try
            user_image = @users_name_dbus[user].IconFile
        catch e
            echo "#{e}"
            
        if not user_image?
            if is_greeter
                user_image = DCore.Greeter.get_user_icon(user)
            else
                user_image = DCore.Lock.get_user_icon(username)
        if not user_image? then user_image = "images/userimg_default.jpg"
        echo "user_image:#{user}-----------#{user_image}------------"
        return user_image

    get_user_id:(user)->
        try
            id = dbus.Uid for dbus in @users_dbus when @users_dbus.UserName is user
        catch e
            echo "#{e}"
        if not id? then id = "1000"
        return id

    is_disable_user :(user)->
        disable = false
        user_dbus = @users_name_dbus[user]
        if user_dbus.Locked is null then disable = false
        else if user_dbus.Locked is true then disable = true
        return disable

    set_blur_background:(user)->
        userid = new String()
        userid = @get_user_id(user)
        echo "current user #{user}'s userid:#{userid}"
        try
            path = @Dbus_Graphic.BackgroundBlurPictPath_sync(userid.toString(),"")
        catch e
            echo "#{GRAPHIC} dbus ERROR:#{e}"
        if path[0]
            BackgroundBlurPictPath = path[1]
        else
            # here should getPath by other methods!
            BackgroundBlurPictPath = path[1]
        echo "BackgroundBlurPictPath:#{BackgroundBlurPictPath}"
        localStorage.setItem("BackgroundBlurPictPath",BackgroundBlurPictPath)
        try
            document.body.style.backgroundImage = "url(#{BackgroundBlurPictPath})"
        catch e
            echo "#{e}"
            document.body.style.backgroundImage = "url(/usr/share/backgrounds/default_background.jpg)"

    new_userinfo_for_greeter:->
        @get_default_username()
        @get_all_users()
        if @_default_username is null then @_default_username = @users_name[0]
        echo "_default_username:#{@_default_username};"
        #@set_blur_background(@_default_username)
        for user in @users_name
            if not @is_disable_user(user)
                userimage = @get_user_image(user)
                u = new UserInfo(user, user, userimage)
                userinfo_all.push(u)
                if user is @_default_username
                    _current_user = u
                    _current_user.only_show_name(false)
                else
                    u.only_show_name(true)
        for user,j in userinfo_all
            user.index = j
        if userinfo_all.length >= 3
            @sort_current_user_info_center()
        else if userinfo_all.length == 1
            _current_user = userinfo_all[0]
            _current_user.only_show_name(false)
        for user,j in userinfo_all
            user.index = j
            user_ul.appendChild(user.element)
            if user is _current_user then _current_user.focus()

        userinfo_show_index =_current_user.index
        localStorage.setItem("current_user_index",userinfo_show_index)
        @prev_next_userinfo_create()
        return userinfo_all

    sort_current_user_info_center:->
        echo "sort_current_user_info_center"
        tmp_length = (userinfo_all.length - 1) / 2
        center_index = Math.round(tmp_length)
        if _current_user.index isnt center_index
            center_old = userinfo_all[center_index]
            userinfo_all[center_index] = _current_user
            userinfo_all[_current_user.index] = center_old
    
    new_userinfo_for_lock:->
        echo "new_userinfo_for_lock"
        user = @get_default_username()
        #@set_blur_background(user)
        userimage = @get_user_image(user)
        _current_user = new UserInfo(user, user, userimage)
        _current_user.only_show_name(false)
        user_ul.appendChild(_current_user.element)
        _current_user.focus()
    
    is_support_guest:->
        if is_greeter
            if DCore.Greeter.is_support_guest()
                u = new UserInfo("guest", _("guest"), "images/guest.jpg")
                u.only_show_name(true)
                user_ul.appendChild(u.element)
                if DCore.Greeter.is_guest_default()
                    u.focus()
    
    get_current_userinfo:->
        return _current_user

    check_index:(index)->
        if index >= userinfo_all.length then index = 0
        else if index < 0 then index = userinfo_all.length - 1
        return index

    prev_next_userinfo_create:->
        prevuserinfo = create_element("div","prevuserinfo",@element)
        @prevuserinfo_img = create_img("prevuserinfo_img",img_src_before + "left_normal.png",prevuserinfo)
        nextuserinfo = create_element("div","nextuserinfo",@element)
        @nextuserinfo_img = create_img("nextuserinfo_img",img_src_before + "right_normal.png",nextuserinfo)
        @normal_hover_click_cb(@prevuserinfo_img,
            img_src_before + "left_normal.png",
            img_src_before + "left_hover.png",
            img_src_before + "left_press.png",
            @switchtoprev_userinfo
        )
        @normal_hover_click_cb(@nextuserinfo_img,
            img_src_before + "right_normal.png",
            img_src_before + "right_hover.png",
            img_src_before + "right_press.png",
            @switchtonext_userinfo
        )

    switchtoprev_userinfo:=>
        echo "switchtoprev_userinfo"
        for user in userinfo_all
            if user.element.style.display is "block"
                user.only_show_name(true)
                apply_animation(user.userimg,"hide_animation",time_animation)
                apply_animation(user.username,"hide_animation",time_animation)
        userinfo_show_index = @check_index(userinfo_show_index + 1)
        localStorage.setItem("current_user_index",userinfo_show_index)
        echo userinfo_show_index
        for user in userinfo_all
            if user.index == userinfo_show_index
                user.only_show_name(false)
                user.animate_prev()
                apply_animation(user.userimg,"show_animation",time_animation)
                apply_animation(user.username,"show_animation",time_animation)


    switchtonext_userinfo:=>
        echo "switchtonext_userinfo"
        for user in userinfo_all
            if user.element.style.display is "block"
                user.only_show_name(true)
                apply_animation(user.userimg,"hide_animation",time_animation)
                apply_animation(user.username,"hide_animation",time_animation)
        userinfo_show_index = @check_index(userinfo_show_index - 1)
        localStorage.setItem("current_user_index",userinfo_show_index)
        echo userinfo_show_index
        for user in userinfo_all
            if user.index == userinfo_show_index
                user.only_show_name(false)
                user.animate_next()
                apply_animation(user.userimg,"show_animation",time_animation)
                apply_animation(user.username,"show_animation",time_animation)


class LoginEntry extends Widget
    img_src_before = "images/userinfo/"
    constructor: (@id, @loginuser,@on_active)->
        super
        if is_greeter then @id = "login"
        else @id = "lock"
        echo "new LoginEntry:#{@id}"
        
        @password_div = create_element("div", "password_div", @element)
        @password = create_element("input", "password", @password_div)
        @password.type = "password"
        @password.setAttribute("maxlength", PasswordMaxlength) if PasswordMaxlength?
        @password.setAttribute("autofocus", true)
       
        @loginbutton = create_img("loginbutton", "", @password_div)
        @loginbutton.type = "button"
        @loginbutton.src = "#{img_src_before}#{@id}_normal.png"
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
        @password_eventlistener()
    

    password_eventlistener:->
        @password.addEventListener("click", (e)=>
            e.stopPropagation()
            if @password.value is password_error_msg or @password.value is localStorage.getItem("password_value_shutdown")
                @input_password_again()
        )
        
        @password.addEventListener("focus",=>
            if @password.value is password_error_msg or @password.value is localStorage.getItem("password_value_shutdown")
                @input_password_again()
        )
        
        document.body.addEventListener("keydown",(e)=>
            if $(".MenuChoose").style.display is "none"
                @password.focus()
        )

        document.body.addEventListener("keyup",(e)=>
            if e.which == ENTER_KEY and $(".MenuChoose").style.display is "none"
                if _current_user.id is @loginuser
                    if @check_completeness()
                        @on_active(@loginuser, @password.value)
            #echo "keyup:#{@password.value}"
        )
#        point = "●"
        #show_text = ""
        #@password.addEventListener("keydown",(e)=>
            #echo e.which
            ##012...9    abc...xyz ABC...xyz  ,./
            ##48---57
            #if e.which == 8
                #show_text = show_text - point
            #else if e.which != ENTER_KEY
                #show_text = show_text + point
            #echo "show_text:#{show_text}"
            #@password.value = show_text

        #)
        @loginbutton.addEventListener("click", =>
            power_flag = false
            if (power = localStorage.getObject("shutdown_from_lock"))?
                if power.lock is true
                    power_flag = true
            if power_flag
                @loginbutton.src = "#{img_src_before}#{power.value}_press.png"
            else
                @loginbutton.src = "#{img_src_before}#{@id}_press.png"
            if @check_completeness
                @on_active(@loginuser, @password.value)
        )
 

    check_completeness: ->
        if is_livecd then return true
        else if not @password.value
            @password.focus()
            return false
        else if @password.value is password_error_msg or @password.value is localStorage.getItem("password_value_shutdown")
            @input_password_again()
            return false
        return true

    input_password_again:->
        @password.style.color = "rgba(255,255,255,0.5)"
        @password.style.fontSize = "2.0em"
        @password.style.paddingBottom = "0.2em"
        @password.style.letterSpacing = "5px"
        @password.type = "password"
        @password.focus()
        @loginbutton.disable = false
        @password.value = null

    password_error:(msg)->
        @password.style.color = "#F4AF53"
        @password.style.fontSize = "1.5em"
        @password.style.paddingBottom = "0.4em"
        @password.style.letterSpacing = "0px"
        @password.type = "text"
        password_error_msg = msg
        @password.value = password_error_msg
        @password.blur()
        @loginbutton.disable = true


class UserInfo extends Widget
    constructor: (@id, name, @img_src)->
        super
        @is_recognizing = false
        @index = null
        echo "new UserInfo :#{@id}"
        @face_login = @userFaceLogin(name)
        
        @userbase = create_element("div", "UserBase", @element)
        
        if @face_login
            @face_recognize_div = create_element("div","face_recognize_div",@userbase)
            @face_recognize_border = create_img("face_recognize_div","images/userinfo/facelogin_boder.png",@face_recognize_div)
            @face_recognize_img = create_img("face_recognize_img","images/userinfo/facelogin_animation.png",@face_recognize_div)
        
        @userimg_div = create_element("div","userimg_div",@userbase)
        @userimg_border = create_element("div","userimg_border",@userimg_div)
        @userimg_background = create_element("div","userimg_background",@userimg_border)
        @userimg = create_img("userimg", @img_src, @userimg_background)
       
        if @face_login
            @face_recognize_div.style.width = 137 * scaleFinal
            @face_recognize_div.style.height = 137 * scaleFinal
            @face_recognize_div.style.left = @userimg_div.style.left
            @face_recognize_div.style.display = "none"
        
        @userimg.style.width = 110 * scaleFinal
        @userimg.style.height = 110 * scaleFinal
        @userimg_border.style.width = @userimg.style.width + 16 * scaleFinal
        @userimg_border.style.height = @userimg.style.height + 16 * scaleFinal
        @userimg_background.style.width = @userimg_border.style.width - 3
        @userimg_background.style.height = @userimg_border.style.height - 3

        @username = create_element("div", "username", @userbase)
        @username.innerText = name

        @login = new LoginEntry("login", @id, (u, p)=>@on_verify(u, p))
        @element.appendChild(@login.element)

        @show_login()

    only_show_name:(hide)->
        if !hide
            @element.style.display= "block"
        else
            @element.style.display= "none"

    userFaceLogin: (name)->
        face = false
        try
            face = DCore[APP_NAME].use_face_recognition_login(name) if hide_face_login
        catch e
            echo "face_login #{e}"
        finally
            return face


    draw_avatar: ->
        if @face_login
            rotate = 0
            @face_recognize_div.style.display = "block"
            @face_animation_interval = setInterval(=>
                @face_recognize_div.style.left = @userimg_div.style.left
                rotate = (rotate + 5) % 360
                animation_rotate(@face_recognize_img,rotate)
            ,50)
            enable_detection(true)

    stop_avatar:->
        if @face_login
            clearInterval(draw_camera_id)
            draw_camera_id = null
            clearInterval(@face_animation_interval) if @face_animation_interval
            @face_recognize_div.style.display = "none"
            enable_detection(false)
            #DCore[APP_NAME].cancel_detect()
   
    focus:->
        echo "#{@id} focus"
        DCore[APP_NAME].set_username(@id) if @face_login
        #@element.focus()
        @draw_camera()
        @draw_avatar()
        @login.password.focus()
        
        if @id != "guest"
            if is_greeter
                @session = DCore.Greeter.get_user_session(@id)
                echo "----------Greeter.get_user_session(#{@id}):---#{@session}---------------------"
                sessions = DCore.Greeter.get_sessions()
                if @session? and @session in sessions
                    de_menu.set_current(@session)
                else
                    echo "----------Greeter.get_user_sessiobn(#{@id}) failed! set_current(deepin)---------"
                    @session = "deepin"
                    de_menu.set_current(@session)
                    echo "#{@id} in focus invalid user session,will not set_current session"
   
    
    blur: ->
        @stop_avatar()


    show_login: ->
        if _current_user == @
            @login.password.focus()

            if @id == "guest"
                @login.password.style.display = "none"
                @login.password.value = "guest"

    on_verify: (username, password)->
        echo "on_verify:#{username},#{password}"

        if is_greeter
            sessions = DCore.Greeter.get_sessions()
            if sessions.length == 1
                de_menu.menu.current = sessions[0]
            session = de_menu.get_current()
            echo "------on_verify:session:#{session}-----------------------"
            if not session?
                echo "get session failed"
                session = "deepin"
            @session = session
            echo 'start session'
            DCore.Greeter.start_session(username, password, @session)
            document.body.cursor = "wait"
            echo 'start session end'
        else
            DCore.Lock.start_session(username,password,@session)
    
    auth_failed: (msg) =>
        @stop_avatar()
        @login.password_error(msg)
        document.body.cursor = "default"


    animate_prev: ->
        if @face_login
            DCore[APP_NAME].cancel_detect()

        if @is_recognizing
            return


    animate_next: ->
        if @face_login
            DCore[APP_NAME].cancel_detect()

        if @is_recognizing
            return

    animate_near: ->
        if @face_login
            DCore[APP_NAME].cancel_detect()

        if @is_recognizing
            return

    draw_camera: ->
        if @face_login
            clearInterval(draw_camera_id)
            draw_camera_id = setInterval(=>
                DCore[APP_NAME].draw_camera(@userimg, @userimg.width, @userimg.height)
            , 20)



DCore.signal_connect("draw", ->
    echo 'receive camera draw signal'
    clearInterval(draw_camera_id)
    draw_camera_id = null
    _current_user.draw_camera()
)

DCore.signal_connect("start-animation", ->
    echo "receive start animation"
    _current_user.is_recognizing = true
    _remove_click_event?()
    _current_user.draw_avatar()
)

DCore.signal_connect("auth-failed", (msg)->
    echo "#{_current_user.id}:[auth-failed]"
    _current_user.is_recognizing = false
    _current_user.auth_failed(msg.error)
)

DCore.signal_connect("failed-too-much", (msg)->
    echo '[failed-too-much]'
    _current_user.is_recognizing = false
    _current_user.auth_failed(msg.error)
    message_tip.adjust_show_login()
)

DCore.signal_connect("auth-succeed", ->
    echo "password_succeed!"
    power_flag = false
    if (power = localStorage.getObject("shutdown_from_lock"))?
        if power.lock is true
            power_flag = true
    if power_flag
        power.lock = false
        localStorage.setObject("shutdown_from_lock",power)
        if power_can(power.value)
            power_force(power.value)
        else
            confirmdialog = new ConfirmDialog(power.value)
            confirmdialog.frame_build()
            document.body.appendChild(confirmdialog.element)
            confirmdialog.interval(60)
    else
        if is_greeter then return
        DCore.Lock.quit()
)

