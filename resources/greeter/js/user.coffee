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
_current_username = null
is_current_user = false
_drag_flag = false
index_prev = null
index_target = null
index_next = null
password_error_msg = null


class User extends Widget
    Dbus_Account = null
    is_livecd = false

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
        @is_livecd()
        Dbus_Account = DCore.DBus.sys("org.freedesktop.Accounts")

        img_src_before = "images/userswitch/"
        prevuserinfo = create_element("div","prevuserinfo",@element)
        @prevuserinfo_img = create_img("prevuserinfo_img",img_src_before + "up_normal.png",prevuserinfo)
        user_ul = create_element("ul","user_ul",@element)
        user_ul.id = "user_ul"
        @new_userinfo_all()
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
     
    is_livecd:->
        try
            dbus = DCore.DBus.sys_object("com.deepin.dde.lock", "/com/deepin/dde/lock", "com.deepin.dde.lock")
            is_livecd = dbus.IsLiveCD_sync(DCore.Lock.get_username())
        catch error
            is_livecd = false
    
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


    new_switchuser:->
        if not is_livecd
            s = new SwitchUser("switchuser")
            s.button_switch()
            @element.appendChild(s.element)
            return s

    get_all_users:->
        users_path = Dbus_Account.ListCachedUsers_sync()
        for user in users_path
            user_dbus = DCore.DBus.sys_object("org.freedesktop.Accounts",user,"org.freedesktop.Accounts.User")
            name = user_dbus.UserName
            realname = user_dbus.RealName
            type = user_dbus.AccountType
            users_realname.push(realname)
            users_name.push(name)
            users_type.push(type)
        return users_name

    get_current_username:->
        if is_greeter
            _current_username = DCore.Greeter.get_default_user()
        else
            _current_username = DCore.Lock.get_username()
        # if _current_user.face_login
        #     message_tip = new MessageTip(SCANNING_TIP, user_ul.parentElement)
        return _current_username

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
        for username,j in users_name
            if user is username
                type = users_type[j]
                switch type
                    when 1 then return _("Administrator")
                    when 0 then return _("Standard user")
                    else return _("Standard user")
        return _("Standard user")

    is_disable_user :(username)->
        disable = false
        users_path = Dbus_Account.ListCachedUsers_sync()
        for u in users_path
            user_dbus = DCore.DBus.sys_object("org.freedesktop.Accounts",u,"org.freedesktop.Accounts.User")
            if username is user_dbus.UserName
                if user_dbus.Locked is null then disable = false
                else if user_dbus.Locked is true then disable = true
                return disable

    new_userinfo_all:()->
        if is_hide_users
            userinfo = new UserInfo("*other", "", "images/huser.jpg",@get_user_type("*other"))
            userinfo.only_show_name(true)
            user_ul.appendChild(userinfo.userinfo_li)
            Widget.look_up("*other").element.style.paddingBottom = "5px"
            userinfo.focus()
        else
            _current_username = @get_current_username()
            users_name = @get_all_users()
            #users = DCore.Greeter.get_users()
            for user in users_name
                if user == _current_username
                    is_current_user = true
                    userimage = @get_user_image(user)
                    _current_user = new UserInfo(user, user, userimage,@get_user_type(user))
                    _current_user.only_show_name(false)
                    userinfo_all.push(_current_user)
                    user_ul.appendChild(_current_user.userinfo_li)
                    _current_user.focus()
            for user in users_name
                if user isnt _current_username and not @is_disable_user(user)
                    is_current_user = false
                    userimage = @get_user_image(user)
                    u = new UserInfo(user, user, userimage,@get_user_type(user))
                    u.only_show_name(true)
                    userinfo_all.push(u)
                    user_ul.appendChild(u.userinfo_li)

#        if is_greeter
            #if DCore.Greeter.is_support_guest()
                #u = new UserInfo("guest", _("guest"), "images/guest.jpg",@get_user_type("guest"))
                #u.only_show_name(true)
                #user_ul.appendChild(u.userinfo_li)
                #if DCore.Greeter.is_guest_default()
                    #u.focus()
        
        if user_ul.children.length <= 2
            user = Widget.look_up(user_ul.children[0].children[0].getAttribute("id"))
        return userinfo_all

    get_current_userinfo:->
        @new_userinfo() if _current_user == null
        return _current_user

    drag:(_current_user)->
        jQuery("#user_ul").drag("start", (ev, dd) ->
            _drag_flag = true
        , {distance:100}
        )

        jQuery("#user_ul").drag("end", (ev, dd) ->
            _current_user?.animate_near()
        )

    import_css:(src)->
        inject_css(@element,src)

    roundabout_animation:->
        jQuery("#user_ul").roundabout({
            shape: 'waterWheel',
            tilt: 2.5,
            minOpacity: 0.0,
            startingChild: 0,
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
            #apply_animation(userinfo_all[index_prev].userinfo_li,"hide_animation","3s")
        )

        .bind("animationEnd",=>
            index_target = jQuery("#user_ul").roundabout("getChildInFocus")
            index_target = @check_index(index_target)
            _current_user = userinfo_all[index_target]
            userinfo_all[index_target].only_show_name(false)
            userinfo_all[index_target].focus()
            apply_animation(userinfo_all[index_target].userinfo_li,"show_animation","1.5s")
            
        )

    check_index:(index)->
        tmp = index
        if index >= userinfo_all.length then tmp = userinfo_all.length - 1
        else if index < 0 then tmp = 0
        return tmp

class LoginEntry extends Widget
    constructor: (@id, @loginuser,@type ,@on_active)->
        super
        # echo "new LoginEntry"
        @usertype = create_element("div","usertype",@element)
        icon_lock = create_element("i","icon-lock",@usertype)
        type_text = create_element("div","type_text",@usertype)
        type_text.textContent = @type

        @capswarning = create_element("div", "capswarning", @element)
        @password = create_element("input", "password", @capswarning)
        @password.type = "password"
        # @password.classList.add("PasswordStyle")
        @password.setAttribute("maxlength", 16)
        # eye = create_element("div","eye",@capswarning)
        # eye.classList.add("opt")
        #@element.setAttribute("autofocus", true)
        

        @loginbutton = create_element("button", "loginbutton", @element)
        @loginbutton.type = "submit"
        if is_greeter
            @loginbutton.innerText = _("Log In")
        else
            @loginbutton.innerText = _("Unlock")
   
        # @check_capslock()
        @password_eventlistener()
    
    password_eventlistener:->
        @password.addEventListener("click", (e)=>
            if @password.value is password_error_msg
                @input_password_again()
        )

        document.body.addEventListener("keyup",(e)=>
            @password.style.color = "black"
            if e.which == ENTER_KEY
                if _current_user.id is @id and @check_completeness
                    if is_hide_users
                        @on_active(@account.value, @password.value)
                    else
                        @on_active(@loginuser, @password.value)
        )

        @loginbutton.addEventListener("click", =>
            echo "#{@id}:loginbutton click"
            if @check_completeness
                if is_hide_users
                    @on_active(@account.value, @password.value)
                else
                    @on_active(@loginuser, @password.value)
        )
 

    check_capslock: ->
        if DCore[APP_NAME].detect_capslock()
            @capswarning.classList.add("CapsWarningBackground")
        else
            @capswarning.classList.remove("CapsWarningBackground")

    check_completeness: ->
        echo "password_error_msg:--#{password_error_msg}--;"
        echo "password.value:---#{@password.value}---"
        if is_hide_users
            if not @account.value
                @account.focus()
                return false
        if not @password.value
            @password.focus()
            return false
        if @password.value is password_error_msg
            @input_password_again()
            return false
        echo "check_completeness true"
        return true

    input_password_again:->
        @password.style.color = "black"
        @password.value = null
        @password.focus()
        @loginbutton.disable = false


    password_error:(msg)->
        @password.style.color = "red"
        password_error_msg = msg
        @password.value = password_error_msg
        @password.blur()
        @loginbutton.disable = true
        echo "password_error"

class Loading extends Widget
    constructor: (@id)->
        super
        create_element("div", "ball", @element)
        create_element("div", "ball1", @element)
        create_element("span", "", @element).innerText = _("Welcome")

class SwitchUser extends Widget
    constructor: (@id)->
        super
        clearInterval(draw_camera_id)
        draw_camera_id = null

    button_switch:->
        @switch = create_element("div", "SwitchGreeter", @element)
        @switch.innerText = _("Switch User")
        @switch.addEventListener("click", =>
            DCore.Lock.switch_user()
        )

    SwitchToGreeter:->
        DCore.Lock.switch_user()

    SwitchToUser:(username,session_name)->
        try
            switch_dbus = DCore.DBus.sys_object("org.freedesktop.DisplayManager","/org/freedesktop/DisplayManager/Seat0","org.freedesktop.DisplayManager.Seat")
            switch_dbus.SwitchToUser_sync(username,session_name)
            echo switch_dbus
        catch error
            echo "can not find the switch dbus,perhaps you only have one userAccount!"
            return false

class UserInfo extends Widget
    userbase = null
    right = null
    img_div = null
    userimg = null
    recognize = null
    username = null
    login_div = null
    constructor: (@id, name, @img_src,@type)->
        super
        @is_recognizing = false
        
        @userinfo_li = create_element("li","userinfo_li",@element)
        @userinfo_li.id = "#{@id}_li"
        @only_name = create_element("div","only_name",@userinfo_li)
        @only_name.innerText = name
        @all_info = create_element("div","all_info",@userinfo_li)
        userbase = create_element("div", "UserBase", @all_info)
        img_div = create_element("div","img_div",userbase)
        userimg = create_img("userimg", @img_src, img_div)
        recognize = create_element("div", "recognize", userbase)
        recognize_h1 = create_element("h1", "", recognize)
        username = create_element("label", "UserName", recognize_h1)
        username.innerText = name

        login_div = create_element("div", "login_div", @all_info)
        @login = new LoginEntry("login", @id,@type, (u, p)=>@on_verify(u, p))
        login_div.appendChild(@login.element)

        if is_greeter then @session = DCore.Greeter.get_user_session(@id)
        else @session = "deepin"

        @show_login()
        @face_login = DCore[APP_NAME].use_face_recognition_login(name)
        @face_login =false


    only_show_name:(only_show_name)->
        if only_show_name
            @userinfo_li.style.background = "rgba(255,250,246,0.0)"
            @userinfo_li.style.borderRadius = "0px"
            @userinfo_li.style.color = "rgba(255,250,246,0.0)"
            @userinfo_li.style.boxShadow = "0 0 0 5px rgba(255,255,255,0.0)"
            
            @only_name.style.display = "block"
            @all_info.style.display = "none"
        else
            @userinfo_li.style.background = "rgba(255,250,246,0.5)"
            @userinfo_li.style.borderRadius = "4px"
            @userinfo_li.style.color = "#7e7975"
            @userinfo_li.style.boxShadow = "0 0 0 5px rgba(255,255,255,0.2)"
            
            @only_name.style.display = "none"
            @all_info.style.display = "-webkit-box"
            

    draw_avatar: ->
        apply_animation(recognize,"recognize_animation","10s") if @face_login
        enable_detection(true) if @face_login

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
        @loading?.destroy()
        @loading = null
        @stop_avatar()


    show_login: ->
        if _current_user == @
            if is_hide_users
                @element.style.paddingBottom = "0px"
                @login.account.focus()
            else
                @login.password.focus()

            if @id == "guest"
                @login.password.style.display = "none"
                @login.password.value = "guest"

    on_verify: (username, password)->
        #@loading = new Loading("loading")
        #@element.appendChild(@loading.element)
        echo "on_verify:#{username},#{password}"

        if not @session?
            echo "get session failed"
            @session = "deepin"
        echo 'start session'

        if is_greeter
            DCore.Greeter.start_session(username, password, @session)
            echo 'start session end'
        else
            if DCore.Lock.try_unlock(username,password)
                echo "try_unlock succeed!"
                if username isnt DCore.Lock.get_username()
                    echo "we must start_session for #{username}"
                    s = new SwitchUser()
                    s.SwitchToUser(username,@session)
    
    auth_failed: (msg) ->
        @stop_avatar()
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

