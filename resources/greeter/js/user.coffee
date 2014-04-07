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
    constructor:->
        super
        
        @userinfo_show_index = 0
        
        @user_session = []
        @userinfo_all = []
        @bg = new Background(APP_NAME)
        @get_default_userid()
        @set_default_session()
    
    set_default_session:->
        @user_session = localStorage.getObject("user_session")
        try
            if @user_session[@_default_username] isnt undefined
                echo @user_session[@_default_username]
                echo "user_session already has"
            else
                echo "user_session is null and set_default"
                default_session = "deepin"
                for name in @bg.users_name
                    echo name
                    @user_session[name] = default_session
                echo @user_session
                localStorage.setObject("user_session",@user_session)
        catch e
            echo "user_session is null and set_default:#{e}"
            default_session = "deepin"
            for name in @bg.users_name
                @user_session[name] = default_session
            localStorage.setObject("user_session",@user_session)
    
    get_default_userid:->
        @_default_username = @bg.get_default_username()
        if @_default_username is null then @_default_username = @bg.users_name[0]
        @_default_userid = @bg.get_user_id(@_default_username)
        echo "_default_username:#{@_default_username};uid:#{@_default_userid}"
        return @_default_userid
    

    new_userinfo_for_greeter:->
        echo "new_userinfo_for_greeter"
        for uid in @bg.users_id
            if not @bg.is_disable_user(uid)
                username = @bg.users_id_dbus[uid].UserName
                usericon = @bg.users_id_dbus[uid].IconFile
                u = new UserInfo(username, username, usericon)
                @userinfo_all.push(u)
                _current_user = u if uid is @_default_userid
        
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
        username = @bg.users_id_dbus[@_default_userid].UserName
        usericon = @bg.users_id_dbus[@_default_userid].IconFile
        _current_user = new UserInfo(username, username, usericon)
        _current_user.index = 0
        _current_user.show()
        @element.appendChild(_current_user.element)
    
    isSupportGuest:->
        if is_support_guest and @bg.isAllowGuest() is true
            guest_image = "images/guest.jpg"
            #guest_image = "/var/lib/AccountsService/icons/guest.jpg"
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
        echo "switchtoprev_userinfo from #{@userinfo_show_index}: #{@userinfo_all[@userinfo_show_index].username}"
        @userinfo_all[@userinfo_show_index].hide_animation()
        @userinfo_show_index = @check_index(@userinfo_show_index + 1)
        localStorage.setItem("current_user_index",@userinfo_show_index)
        echo "switchtoprev_userinfo to #{@userinfo_show_index}: #{@userinfo_all[@userinfo_show_index].username}"
        @userinfo_all[@userinfo_show_index].show_animation()
        @userinfo_all[@userinfo_show_index].animate_prev()

    switchtonext_userinfo : =>
        echo "switchtonext_userinfo from #{@userinfo_show_index}: #{@userinfo_all[@userinfo_show_index].username}"
        @userinfo_all[@userinfo_show_index].hide_animation()
        @userinfo_show_index = @check_index(@userinfo_show_index - 1)
        localStorage.setItem("current_user_index",@userinfo_show_index)
        echo "switchtonext_userinfo to #{@userinfo_show_index}: #{@userinfo_all[@userinfo_show_index].username}"
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
    



class UserInfo extends Widget
    constructor: (@id, @username, @img_src)->
        super
        echo "new UserInfo :#{@username}"
        
        @is_recognizing = false
        @index = null
        @time_animation = 500
        @face_login = @userFaceLogin(@username)
        
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

        @username_div = create_element("div", "username_div", @userbase)
        @username_div.innerText = @username
        @username_div.style.display = "none"

        @login = new LoginEntry("login", @username, (u, p)=>@on_verify(u, p))
        @element.appendChild(@login.element)
        @login.hide()

        #@loginAnimation()
    
    
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
        @focus()

    hide_animation:->
        @username_div.style.display = "none"
        @login.hide()
        
        @userimg.style.opacity = "1.0"
        jQuery(@userimg).animate({opacity:'0.0'},@time_animation,
            "linear",=>
                @userimg_div.style.display = "none"
                @element.style.display = "none"
                @blur()
        )
    
    show_animation:->
        @show()
        @userimg.style.opacity = "0.0"
        jQuery(@userimg).animate({opacity:'1.0'},@time_animation)

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
        rotate = 0
        rotate_animation = =>
            @face_recognize_div.style.display = "block"
            @face_animation_interval = setInterval(=>
                @face_recognize_div.style.left = @userimg_div.style.left
                rotate = (rotate + 5) % 360
                animation_rotate(@face_recognize_img,rotate)
            ,20)
        
        @auth_time = 500#test is 85
        @auth_timeout = setTimeout(rotate_animation,@auth_time)
    
    loginAnimationClear: ->
        echo "loginAnimationClear"
        @face_recognize_div.style.display = "none"
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
   
    update_session_icon: ->
        echo "update_session_icon"
        if is_greeter
            @user_session = localStorage.getObject("user_session")
            echo @user_session
            
            @session = DCore.Greeter.get_user_session(@username)
            echo "----Greeter.get_user_session(#{@username}):---#{@session}--------"
            sessions = DCore.Greeter.get_sessions()
            if @session? and @session in sessions
                echo "#{@username} session  is #{@session} "
            else
                @session = @user_session[@username]
                echo "-session get from @user_session[#{@username}] = #{@session}---------"
            de_menu?.set_current(@session)

    focus:->
        echo "#{@username} focus"
        @login.password.focus() if @username isnt "guest"

        if @face_login
            DCore[APP_NAME].set_username(@username)
            @draw_camera()
            @draw_avatar()
        
        _current_user = @
        @update_session_icon() if is_greeter
 
    
    blur: ->
        @loginAnimationClear()
        @stop_avatar()


    on_verify: (username, password)->
        echo "on_verify:#{username}"
        echo  "--------#{new Date().getTime()}-----------"
        if is_greeter
            echo "#{username} start session #{@session}"
            @loginAnimation()
            @user_session[username] = @session
            localStorage.setObject("user_session",@user_session)
            DCore.Greeter.start_session(username, password, @session)
            document.body.cursor = "wait"
            echo "start session end"
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
        if @is_recognizing
            return

    animate_next: ->
        if @face_login
            DCore[APP_NAME].cancel_detect()
        if @is_recognizing
            return


class LoginEntry extends Widget
    img_src_before = "images/userinfo/"
    constructor: (@id, @username,@on_active)->
        super
        if is_greeter then @id = "login"
        else @id = "lock"
        echo "new LoginEntry:#{@id}"
        
        @password_div = create_element("div", "password_div", @element)
        @password = create_element("input", "password", @password_div)
        @password.type = "password"
        @password.setAttribute("maxlength", PasswordMaxlength) if PasswordMaxlength?
        @password.setAttribute("autofocus", true) if @username isnt "guest"
       
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
        
        if @username is "guest"
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
            if @username is "guest" then return
            if @password.value is password_error_msg or @password.value is localStorage.getItem("password_value_shutdown")
                @input_password_again()
        )
        
        @password.addEventListener("focus",=>
            if @username is "guest" then return
            if @password.value is password_error_msg or @password.value is localStorage.getItem("password_value_shutdown")
                @input_password_again()
        )
        
        @password.addEventListener("keyup",(e)=>
            if @username is "guest" then return
            if e.which == ENTER_KEY
                # if _current_user.username is @username
                @on_active(@username, @password.value) if @check_completeness()
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
                @on_active(@username, @password.value)
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
    echo "#{_current_user.username}:[auth-failed]"
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

