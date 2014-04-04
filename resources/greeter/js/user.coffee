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
    ACCOUNTS_DAEMON = "com.deepin.daemon.Accounts"
    ACCOUNTS_USER =
        obj: ACCOUNTS_DAEMON
        path: "/com/deepin/daemon/Accounts/User1000"
        interface: "com.deepin.daemon.Accounts.User"
    
    GRAPHIC = "com.deepin.api.Graphic"

    img_src_before = "images/userswitch/"
    
    constructor:->
        super
        
        @userinfo_show_index = 0

        @users_dbus = []
        @users_name = []
        @users_id = []
        @users_id_dbus = []
        @users_name_dbus = []
        @userinfo_all = []
    
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
        jQuery(el).hover((e)->
            el.src = hover
            el.style.opacity = "0.8"
        ,(e)->
            el.src = normal
        )
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

    get_user_icon:(user) ->
        try
            icon = @users_name_dbus[user].IconFile
        catch e
            echo "#{e}"
        if not icon? then icon = DCore[APP_NAME].get_user_icon(user)
        if not icon? then icon = "images/userimg_default.jpg"
        echo "icon:#{user}-----------#{icon}------------"
        return icon

    get_user_id:(user)->
        id = null
        try
            id = @users_name_dbus[user].Uid
        catch e
            echo "get_user_id #{e}"
        if not id? then id = "1000"
        return id


    is_disable_user :(user)->
        disable = false
        user_dbus = @users_name_dbus[user]
        if user_dbus.Locked is null then disable = false
        else if user_dbus.Locked is true then disable = true
        return disable


    new_userinfo_for_greeter:->
        echo "new_userinfo_for_greeter"
        @get_default_username()
        @get_all_users()
        if @_default_username is null then @_default_username = @users_name[0]
        echo "_default_username:#{@_default_username};"
        for user in @users_name
            if not @is_disable_user(user)
                userimage = @get_user_icon(user)
                u = new UserInfo(user, user, userimage)
                @userinfo_all.push(u)
                _current_user = u if user is @_default_username
        
        user.index = j for user,j in @userinfo_all
        _current_user = @userinfo_all[0] if not _current_user?
        if @userinfo_all.length >= 3 then @sort_current_user_info_center()
        for user,j in @userinfo_all
            @element.appendChild(user.element)
            if user.index is _current_user.index
                _current_user.show()
            else
                user.hide()
        
        return @userinfo_all

    sort_current_user_info_center:->
        echo "sort_current_user_info_center"
        tmp_length = (@userinfo_all.length - 1) / 2
        center_index = Math.round(tmp_length)
        if _current_user.index != center_index
            center_old = @userinfo_all[center_index]
            @userinfo_all[center_index] = _current_user
            @userinfo_all[_current_user.index] = center_old
            _current_user.index = center_index
        @userinfo_show_index =_current_user.index
        localStorage.setItem("current_user_index",@userinfo_show_index)
    
    new_userinfo_for_lock:->
        echo "new_userinfo_for_lock"
        user = @get_default_username()
        userimage = @get_user_icon(user)
        _current_user = new UserInfo(user, user, userimage)
        _current_user.index = 0
        _current_user.show()
        @element.appendChild(_current_user.element)
    
    isSupportGuest:->
        @AllowGuest = @Dbus_Account.AllowGuest
        if is_support_guest and @AllowGuest
            guest_image = "/var/lib/AccountsService/icons/guest.jpg"
            u = new UserInfo("guest", _("guest"), guest_image)
            u.hide()
            @userinfo_all.push(u)
            @element.appendChild(u.element)
            if DCore.Greeter.is_guest_default() then u.show()
    
    get_current_userinfo:->
        return _current_user

    check_index:(index)->
        if index >= @userinfo_all.length then index = 0
        else if index < 0 then index = @userinfo_all.length - 1
        return index

    showCurrentSession : (user)=>
        echo "showCurrentSession:#{user}"


    switchtoprev_userinfo : =>
        echo "switchtoprev_userinfo from #{@userinfo_show_index}: #{@userinfo_all[@userinfo_show_index].id}"
        @userinfo_all[@userinfo_show_index].hide_animation()
        @userinfo_show_index = @check_index(@userinfo_show_index + 1)
        localStorage.setItem("current_user_index",@userinfo_show_index)
        echo "switchtoprev_userinfo to #{@userinfo_show_index}: #{@userinfo_all[@userinfo_show_index].id}"
        @userinfo_all[@userinfo_show_index].show_animation()
        @userinfo_all[@userinfo_show_index].animate_prev()

    switchtonext_userinfo : =>
        echo "switchtonext_userinfo from #{@userinfo_show_index}: #{@userinfo_all[@userinfo_show_index].id}"
        @userinfo_all[@userinfo_show_index].hide_animation()
        @userinfo_show_index = @check_index(@userinfo_show_index - 1)
        localStorage.setItem("current_user_index",@userinfo_show_index)
        echo "switchtonext_userinfo to #{@userinfo_show_index}: #{@userinfo_all[@userinfo_show_index].id}"
        @userinfo_all[@userinfo_show_index].show_animation()
        @userinfo_all[@userinfo_show_index].animate_next()


    prev_next_userinfo_create:->
        @switchuser_div = create_element("div","switchuser_div",@element)
        @prevuserinfo = create_element("div","prevuserinfo",@switchuser_div)
        @prevuserinfo_img = create_img("prevuserinfo_img",img_src_before + "left_normal.png",@prevuserinfo)
        @nextuserinfo = create_element("div","nextuserinfo",@switchuser_div)
        @nextuserinfo_img = create_img("nextuserinfo_img",img_src_before + "right_normal.png",@nextuserinfo)

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
        @password.setAttribute("autofocus", true) if @loginuser isnt "guest"
       
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
        
        if @loginuser is "guest"
            @password_error(_("click login button to log in"))
            @loginbutton.disable = false
            @loginbutton.style.pointer = "cursor"

    show:->
        @element.style.display = "-webkit-box"
        @password.focus()

    hide:->
        @element.style.display = "none"
        @password.blur()


    password_eventlistener:->
        @password.addEventListener("click", (e)=>
            e.stopPropagation()
            if @loginuser is "guest" then return
            if @password.value is password_error_msg or @password.value is localStorage.getItem("password_value_shutdown")
                @input_password_again()
        )
        
        @password.addEventListener("focus",=>
            if @loginuser is "guest" then return
            if @password.value is password_error_msg or @password.value is localStorage.getItem("password_value_shutdown")
                @input_password_again()
        )
        
        @password.addEventListener("keyup",(e)=>
            if @loginuser is "guest" then return
            if e.which == ENTER_KEY
        #document.body.addEventListener("keyup",(e)=>
            #if e.which == ENTER_KEY and $(".MenuChoose").style.display is "none"
                if _current_user.id is @loginuser
                    if @check_completeness()
                        @on_active(@loginuser, @password.value)
            #echo "keyup:#{@password.value}"
        )

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
                @on_active(@loginuser, @password.value)
        )
        
        document.body.addEventListener("keydown",(e)=>
            if $(".MenuChoose").style.display is "none"
                @password.focus()
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
        echo "new UserInfo :#{@id}"
        
        @is_recognizing = false
        @index = null
        @time_animation = 500
        @face_login = @userFaceLogin(name)
        
        @userbase = create_element("div", "UserBase", @element)
        
        @face_recognize_div = create_element("div","face_recognize_div",@userbase)
        #@face_recognize_border = create_img("face_recognize_div","images/userinfo/facelogin_boder.png",@face_recognize_div)
        @face_recognize_img = create_img("face_recognize_img","images/userinfo/facelogin_animation.png",@face_recognize_div)
        
        @userimg_div = create_element("div","userimg_div",@userbase)
        @userimg_border = create_element("div","userimg_border",@userimg_div)
        @userimg_background = create_element("div","userimg_background",@userimg_border)
        @userimg = create_img("userimg", @img_src, @userimg_background)
        @userimg_div.style.display = "none"
        
        echo "-------scaleFinal =  #{scaleFinal}-----------------"
        @face_recognize_div.style.width = 135 * scaleFinal
        @face_recognize_div.style.height = 135 * scaleFinal
        @face_recognize_div.style.left = @userimg_div.style.left + 25
        @face_recognize_div.style.display = "none"
        
        @userimg.style.width = 110 * scaleFinal
        @userimg.style.height = 110 * scaleFinal
        @userimg_border.style.width = @userimg.style.width + 16 * scaleFinal
        @userimg_border.style.height = @userimg.style.height + 16 * scaleFinal
        @userimg_background.style.width = @userimg_border.style.width - 3
        @userimg_background.style.height = @userimg_border.style.height - 3

        @username = create_element("div", "username", @userbase)
        @username.innerText = name
        @username.style.display = "none"

        @login = new LoginEntry("login", @id, (u, p)=>@on_verify(u, p))
        @element.appendChild(@login.element)
        @login.hide()

        #@loginAnimation()
    
    
    hide:=>
        @userimg_div.style.display = "none"
        @username.style.display = "none"
        @login.hide()
        @element.style.display = "none"
        @blur()

    show:=>
        @userimg_div.style.display = "-webkit-box"
        @username.style.display = "block"
        @login.show()
        @element.style.display = "-webkit-box"
        @focus()

    hide_animation:->
        @login.hide()
        @username.style.display = "none"

        @userimg.style.opacity = "1.0"
        jQuery(@userimg).animate(
            {opacity:'0.0'},
            @time_animation,
            "linear",=>
                @hide)
    
    show_animation:->
        @login.show()
        @show()
        @username.style.display = "block"
        
        @userimg.style.opacity = "0.0"
        jQuery(@userimg).animate(
            {opacity:'1.0'},
            @time_animation)

    userFaceLogin: (name)->
        face = false
        try
            face = DCore[APP_NAME].use_face_recognition_login(name) if hide_face_login
        catch e
            echo "face_login #{e}"
        finally
            return face
    
    draw_camera: ->
        if !@face_login then return
        clearInterval(draw_camera_id)
        draw_camera_id = setInterval(=>
            DCore[APP_NAME].draw_camera(@userimg, @userimg.width, @userimg.height)
        , 20)

    loginAnimation: ->
        echo "loginAnimation"
        #return
        rotate = 0
        rotate_animation = =>
            @face_recognize_div.style.display = "block"
            @face_animation_interval = setInterval(=>
                @face_recognize_div.style.left = @userimg_div.style.left
                rotate = (rotate + 5) % 360
                animation_rotate(@face_recognize_img,rotate)
            ,20)
        
        @timeout = setTimeout(rotate_animation,800)
    
    loginAnimationClear: ->
        echo "loginAnimationClear"
        @face_recognize_div.style.display = "none"
        clearTimeout(@timeout) if @timeout
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
   
    focus:->
        echo "#{@id} focus"
        @login.password.focus() if @id isnt "guest"

        if @face_login
            DCore[APP_NAME].set_username(@id)
            @draw_camera()
            @draw_avatar()
        
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
        @loginAnimationClear()
        @stop_avatar()


    on_verify: (username, password)->
        echo "on_verify:#{username}"
        echo  "--------#{new Date().getTime()}-----------"
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
            @loginAnimation()
            DCore.Greeter.start_session(username, password, @session)
            document.body.cursor = "wait"
            echo 'start session end'
        else
            @loginAnimation()
            DCore.Lock.start_session(username,password,@session)
    
    auth_failed: (msg) =>
        @loginAnimationClear()
        @stop_avatar()
        @login.password_error(msg)

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
    echo  "--------#{new Date().getTime()}-----------"
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
    echo  "--------#{new Date().getTime()}-----------"
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
        if is_greeter
            echo "greeter exit"
        else
            enableZoneDetect(true)
            DCore.Lock.quit()
            echo "dlock exit"
)

