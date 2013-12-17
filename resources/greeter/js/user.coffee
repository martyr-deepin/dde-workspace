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
_default_username = null
_drag_flag = false
password_error_msg = null


class User extends Widget
    Dbus_Account = null
    img_src_before = null

    username = null
    userimage = null
    userinfo = null
    userinfo_all = []
        
    users_path = []
    users_name = []
    users_realname = []
    users_type = []
    constructor:->
        super
        Dbus_Account = DCore.DBus.sys("org.freedesktop.Accounts")
        img_src_before = "images/userswitch/"
        user_ul = create_element("ul","user_ul",@element)
        user_ul.id = "user_ul"
    
   
    normal_hover_click_cb: (el,normal,hover,click,click_cb) ->
        el.addEventListener("mouseover",->
            el.src = hover
        ) if hover
        el.addEventListener("mouseout",->
            el.src = normal
        ) if normal
        el.addEventListener("click",=>
            el.src = click
            click_cb?()
        ) if click


    get_all_users:->
        users_path = Dbus_Account.ListCachedUsers_sync()
        echo users_path
        for path in users_path
            user_dbus = DCore.DBus.sys_object("org.freedesktop.Accounts",path,"org.freedesktop.Accounts.User")
            name = user_dbus.UserName
            realname = user_dbus.RealName
            type = user_dbus.AccountType
            users_realname.push(realname)
            users_name.push(name)
            users_type.push(type)
        echo users_name
        return users_name

    get_default_username:->
        if is_greeter
            _default_username = DCore.Greeter.get_default_user()
        else
            _default_username = DCore.Lock.get_username()
        # if _current_user.face_login
        #     message_tip = new MessageTip(SCANNING_TIP, user_ul.parentElement)
        return _default_username

    get_user_image:(user) ->
        try
            if is_greeter
                user_image = DCore.Greeter.get_user_icon(user)
            else
                user_image = DCore.Lock.get_user_icon(username)
        catch error
            echo error

        if not user_image?
            try
                user_image = DCore.DBus.sys_object("com.deepin.passwdservice", "/", "com.deepin.passwdservice").get_user_fake_icon_sync(user)
            catch error
                user_image = "images/img01.jpg"

        return user_image

    get_user_type:(user)->
        if users_type.length == 0 or users_name.length == 0 then @get_all_users()
        for tmp,j in users_name
            if user is tmp
                type = users_type[j]
                switch type
                    when 1 then return _("Administrator")
                    when 0 then return _("Standard user")
                    else return _("Standard user")
        return _("Standard user")

    is_disable_user :(user)->
        disable = false
        users_path = Dbus_Account.ListCachedUsers_sync()
        for u in users_path
            user_dbus = DCore.DBus.sys_object("org.freedesktop.Accounts",u,"org.freedesktop.Accounts.User")
            if user is user_dbus.UserName
                if user_dbus.Locked is null then disable = false
                else if user_dbus.Locked is true then disable = true
                return disable

    new_userinfo_for_greeter:->
        _default_username = @get_default_username()
        users_name = @get_all_users()
        #users_name = DCore.Greeter.get_users()
       
        for user in users_name
            if not @is_disable_user(user)
                userimage = @get_user_image(user)
                u = new UserInfo(user, user, userimage,@get_user_type(user))
                if user is _default_username
                    _current_user = u
                    _current_user.only_show_name(false)
                else
                    u.only_show_name(true)
                userinfo_all.push(u)
        for user,j in userinfo_all
            user.index = j
        @sort_current_user_info_center()
        return userinfo_all

    new_userinfo_for_lock:->
        user_ul.style.height = "400px"
        user_ul.style.display = "-webkit-box"
        user_ul.style.WebkitBoxAlign = "center"
        user_ul.style.WebkitBoxPack = "center"
        
        user = @get_default_username()
        userimage = @get_user_image(user)
        _current_user = new UserInfo(user, user, userimage,@get_user_type(user))
        _current_user.only_show_name(false)
        user_ul.appendChild(_current_user.userinfo_li)
        _current_user.focus()
    
    is_support_guest:->
        if is_greeter
            if DCore.Greeter.is_support_guest()
                u = new UserInfo("guest", _("guest"), "images/guest.jpg",@get_user_type("guest"))
                u.only_show_name(true)
                user_ul.appendChild(u.userinfo_li)
                if DCore.Greeter.is_guest_default()
                    u.focus()
       
    sort_current_user_info_center:->
        tmp_length = (userinfo_all.length - 1) / 2
        center_index = Math.round(tmp_length)
        if _current_user.index == center_index then return
        
        center_old = userinfo_all[center_index]
        userinfo_all[center_index] = _current_user
        userinfo_all[_current_user.index] = center_old
        for user,j in userinfo_all
            user.index = j
            user_ul.appendChild(user.userinfo_li)
            if user is _current_user then _current_user.focus()

    get_current_userinfo:->
        return _current_user

    username_font_animation:(FocusChildIndex)->
        prev = @check_index(FocusChildIndex - 1)
        next = @check_index(FocusChildIndex + 1)
        
        for i in [0 ... (userinfo_all.length) / 2]
            #if @check_index(FocusChildIndex - i) is FocusChildIndex or @check_index(FocusChildIndex + i) is @FocusChildIndex then break
            size = 26 - i * 6
            if size < 13 then size = 13
            userinfo_all[@check_index(FocusChildIndex - i)].only_name.style.fontSize = size
            userinfo_all[@check_index(FocusChildIndex + i)].only_name.style.fontSize = size


    check_index:(index)->
        if index >= userinfo_all.length then index = 0
        else if index < 0 then index = userinfo_all.length - 1
        return index

    prev_next_userinfo_create:->
        prevuserinfo = create_element("div","prevuserinfo",@element)
        @prevuserinfo_img = create_img("prevuserinfo_img",img_src_before + "up_normal.png",prevuserinfo)
        #@username_font_animation(_current_user.index)
        nextuserinfo = create_element("div","nextuserinfo",@element)
        @nextuserinfo_img = create_img("nextuserinfo_img",img_src_before + "down_normal.png",nextuserinfo)
#        if user_ul.children.length > 5
            #@prevuserinfo.style.display = "block"
            #@nextuserinfo.style.display = "block"
        @normal_hover_click_cb(@prevuserinfo_img,
            img_src_before + "up_normal.png",
            img_src_before + "up_hover.png",
            img_src_before + "up_press.png"
        )
        @normal_hover_click_cb(@nextuserinfo_img,
            img_src_before + "down_normal.png",
            img_src_before + "down_hover.png",
            img_src_before + "down_press.png"
        )


    roundabout_animation:->
        echo "roundabout_animation"
        #inject_js("js/roundabout/jquery.roundabout.js")
        #inject_js("js/roundabout/jquery.roundabout-shapes.js")
        @prev_next_userinfo_create()

        jQuery("#user_ul").roundabout({
            shape: 'waterWheel',
            tilt: 2.3,
            minZ: 180,
            minOpacity: 0.0,
            startingChild: _current_user.index,
            clickToFocus: true,
            enableDrag: false,
            triggerFocusEvents: true,
            triggerBlurEvents: true,
            
            btnNext: jQuery(".prevuserinfo_img"),
            btnPrev: jQuery(".nextuserinfo_img")
        })
        .bind("animationStart",=>
            index_prev = jQuery("#user_ul").roundabout("getChildInFocus")
            index_prev = @check_index(index_prev)
            userinfo_all[index_prev].blur()
            userinfo_all[index_prev].only_show_name(true)
        )

        .bind("animationEnd",=>
            index_target = jQuery("#user_ul").roundabout("getChildInFocus")
            index_target = @check_index(index_target)
            _current_user = userinfo_all[index_target]
            userinfo_all[index_target].only_show_name(false)
            userinfo_all[index_target].focus()
            apply_animation(userinfo_all[index_target].userinfo_li,"show_animation","1.5s")
            #@username_font_animation(_current_user.index)
        )
 
    jCarousel_animation:->
        echo "jCarousel_animation"
        @prev_next_userinfo_create()
        # @element.style.overflow = "hidden"
        #@prev_next_userinfo_create()

        jQuery(".User").jcarousel({
            vertical: true,
            rtl: false,
            list: '.user_ul',
            items: '.userinfo_li',
            animation: 'slow',
            wrap: 'circular',
            center: true
        })
        jQuery(".User").jcarousel('scroll','+=2')
        jQuery(".User").jcarousel('reload')
        echo jQuery(".User")
        @username_font_animation(_current_user.index)

 class LoginEntry extends Widget
    constructor: (@id, @loginuser,@type ,@on_active)->
        super
        # echo "new LoginEntry"
        @usertype = create_element("div","usertype",@element)
        icon_lock = create_element("div","icon_lock",@usertype)
        icon_lock.style.backgroundImage = "url(images/userswitch/lock.png)"
        type_text = create_element("div","type_text",@usertype)
        type_text.textContent = @type

        @password_div = create_element("div", "password_div", @element)
        @password = create_element("input", "password", @password_div)
        @password.type = "password"
        @password.setAttribute("maxlength", 16)
        @password.setAttribute("autofocus", true)
        @eye = create_element("div","eye",@password_div)
        @eye.style.backgroundImage = "url(images/userswitch/eye_show.png)"
        @eye.addEventListener("click",=>
            @show_hide_password()
            if @password.type is "password"
                @eye.style.backgroundImage = "url(images/userswitch/eye_show.png)"
                icon_lock.style.backgroundImage = "url(images/userswitch/lock.png)"
            else
                @eye.style.backgroundImage = "url(images/userswitch/eye_hide.png)"
                icon_lock.style.backgroundImage = "url(images/userswitch/unlock.png)"
                
        )
        

        @loginbutton = create_element("button", "loginbutton", @element)
        @loginbutton.type = "submit"
        if is_greeter
            @loginbutton.innerText = _("Log In")
        else
            @loginbutton.innerText = _("Unlock")
   

        @password_eventlistener()
    

    password_eventlistener:->
        @password.addEventListener("click", (e)=>
            if @password.value is password_error_msg
                @input_password_again()
        )
        
        document.body.addEventListener("keyup",(e)=>
            if e.which == ENTER_KEY
                if _current_user.id is @loginuser
                    if @check_completeness()
                        @on_active(@loginuser, @password.value)
        )

        @loginbutton.addEventListener("click", =>
            if @check_completeness
                @on_active(@loginuser, @password.value)
        )
 

    check_completeness: ->
        if not @password.value
            @password.focus()
            return false
        else if @password.value is password_error_msg
            @input_password_again()
            return false
        return true

    input_password_again:->
        @password.style.color = "black"
        @password.value = null
        @password.type = "password"
        @password.focus()
        @loginbutton.disable = false
        @loginbutton.style.background = "#fbd568"

    password_error:(msg)->
        @password.style.color = "red"
        @password.type = "text"
        password_error_msg = msg
        @password.value = password_error_msg
        @password.blur()
        @loginbutton.disable = true
        @loginbutton.style.background = "#808080"

    show_hide_password:->
        if @password.type is "password" then @password.type = "text"
        else if @password.type is "text" then @password.type = "password"


class UserInfo extends Widget
    userimg = null
    recognize = null
    constructor: (@id, name, @img_src,@type)->
        super
        @is_recognizing = false
        @index = null
        echo @id
        @userinfo_li = create_element("li","userinfo_li",@element)
        @userinfo_li.id = "#{@id}_li"
        @only_name = create_element("div","only_name",@userinfo_li)
        @only_name.innerText = name
        
        
        @only_info = create_element("div","only_info",@userinfo_li)
        @only_info_background = create_element("div","only_info_background",@only_info)
        userbase = create_element("div", "UserBase", @only_info_background)
        img_div = create_element("div","img_div",userbase)
        userimg = create_img("userimg", @img_src, img_div)
        recognize = create_element("div", "recognize", userbase)
        recognize_h1 = create_element("h1", "recognize_h1", recognize)
        @username = create_element("label", "UserName", recognize_h1)
        @username.innerText = name

        login_div = create_element("div", "login_div", @only_info_background)
        @login = new LoginEntry("login", @id,@type, (u, p)=>@on_verify(u, p))
        login_div.appendChild(@login.element)

        @glass = create_element("p","glass",@only_info)
        
        if is_greeter then @session = DCore.Greeter.get_user_session(@id)
        else @session = "deepin"

        @show_login()
        @face_login = DCore[APP_NAME].use_face_recognition_login(name)
        @face_login =false


    only_show_name:(only_show_name)->
        if only_show_name
            @only_name.style.display = "block"
            @glass.style.display = "none"
            @only_info.style.display = "none"
        else
            @only_name.style.display = "none"
            @glass.style.display = "block"
            @only_info.style.display = "block"
            

    draw_avatar: ->
        if @face_login
            recognize.style.background = "url(images/light.png) repeat black"
            recognize.style.webkitBackgroundClip = "text"
            recognize.style.webkitTextFill = "transparent"
            recognize.style.webkitAnimationName = "recognize_animation"
            recognize.style.webkitAnimationDuration = "10s"
            recognize.style.webkitAnimationIteration = "infinite"
            recognize.style.webkitAnimationTimingFunction = "linear"
            enable_detection(true)

    stop_avatar:->
        clearInterval(draw_camera_id)
        draw_camera_id = null
        apply_animation(recognize,"","") if @face_login
        enable_detection(false) if @face_login
        #DCore[APP_NAME].cancel_detect()
   
    focus:->
        echo "#{@id} focus"
        DCore[APP_NAME].set_username(@id)
        #@element.focus()
        @draw_camera()
        @draw_avatar()
        @login.password.focus()
        
        if is_greeter
            remove_element(jQuery(".DesktopMenu")) if jQuery(".DesktopMenu")
            #if @session then de_menu.set_current(@session)
            desktopmenu = new DesktopMenu($("div_desktop"))
            desktopmenu.new_desktop_menu()
    
    
    blur: ->
        #@loading?.destroy()
        #@loading = null
        @stop_avatar()


    show_login: ->
        if _current_user == @
            @login.password.focus()

            if @id == "guest"
                @login.password.style.display = "none"
                @login.password.value = "guest"

    on_verify: (username, password)->
        #@loading = new Loading("loading")
        #@only_info.appendChild(@loading.element)
        echo "on_verify:#{username},#{password}"

        if not @session?
            echo "get session failed and session default deepin"
            @session = "deepin"

        if is_greeter
            echo 'start session'
            DCore.Greeter.start_session(username, password, @session)
            echo 'start session end'
        else
            DCore.Lock.start_session(username,password,@session)
    
    auth_failed: (msg) ->
        @stop_avatar()
        #@loading?.destroy()
        #@loading = null
        # message_tip?.remove()
        # message_tip = null
        # message_tip = new MessageTip(msg, user_ul.parentElement)
        @login.password_error(msg)


    animate_prev: ->
        if @face_login
            DCore[APP_NAME].cancel_detect()

        if @is_recognizing
            return

        jQuery("#user_ul").roundabout("animateToPreviousChild")

    animate_next: ->
        if @face_login
            DCore[APP_NAME].cancel_detect()

        if @is_recognizing
            return

        jQuery("#user_ul").roundabout("animateToNextChild")

    animate_near: ->
        if @face_login
            DCore[APP_NAME].cancel_detect()

        if @is_recognizing
            return
        jQuery("#user_ul").roundabout("animateToNearestChild")

    draw_camera: ->
        if @face_login
            clearInterval(draw_camera_id)
            draw_camera_id = setInterval(=>
                DCore[APP_NAME].draw_camera(userimg, userimg.width, userimg.height)
            , 20)



class Loading extends Widget
    constructor: (@id)->
        super
        create_element("div", "ball", @element)
        create_element("div", "ball1", @element)
        create_element("span", "", @element).innerText = _("Welcome")



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

