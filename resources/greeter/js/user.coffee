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

user_ul = null
message_tip = null
draw_camera_id = null
_current_user = null
userinfo_list = []
_drag_flag = false


class User extends Widget
    Dbus_Account = null
    is_livecd = false

    username = null
    userimage = null
    userinfo = null
    userinfo_all = []
    _current_username = null

        
    users_path = []
    users_name = []
    users_realname = []
    users_type = []
    constructor:->
        super
        @is_livecd()
        
        user_ul = create_element("ul","user_ul",@element)
        user_ul.id = "user_ul"
    
    is_livecd:->
        try
            Dbus_Account = DCore.DBus.sys("org.freedesktop.Accounts")
            dbus = DCore.DBus.sys_object("com.deepin.dde.lock", "/com/deepin/dde/lock", "com.deepin.dde.lock")
            is_livecd = dbus.IsLiveCD_sync(DCore.Lock.get_username())
        catch error
            is_livecd = false

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

    new_userinfo_all:()->
        if is_hide_users
            userinfo = new UserInfo("*other", "", "images/huser.jpg",@get_user_type("*other"))
            user_ul.appendChild(userinfo.userinfo_li)
            Widget.look_up("*other").element.style.paddingBottom = "5px"
            userinfo.focus()
        else
            _current_username = @get_current_username()
            users_name = @get_all_users()
            #users = DCore.Greeter.get_users()
            for user in users_name
                if user == _current_username
                    userimage = @get_user_image(user)
                    _current_user = new UserInfo(user, user, userimage,@get_user_type(user))
                    userinfo_all.push(_current_user)
                    user_ul.appendChild(_current_user.userinfo_li)
                    _current_user.focus()
                else
                    userimage = @get_user_image(user)
                    u = new UserInfo(user, user, userimage,@get_user_type(user))
                    userinfo_all.push(u)
                    user_ul.appendChild(u.userinfo_li)


        if user_ul.children.length <= 2
            user = Widget.look_up(user_ul.children[0].children[0].getAttribute("id"))
        return userinfo_all

        if DCore.Greeter.is_support_guest() and is_greeter
            u = new UserInfo("guest", _("guest"), "images/guest.jpg",@get_user_type("guest"))
            user_ul.appendChild(u.userinfo_li)
            if DCore.Greeter.is_guest_default()
                u.focus()
    
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


class LoginEntry extends Widget
    constructor: (@id, @loginuser,@type ,@on_active)->
        super
        # echo "new LoginEntry"
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
        @element.setAttribute("autofocus", true)
        
        # @check_capslock()

        @password.addEventListener("keyup", (e)=>
            @password.style.color = "black"
            #@check_capslock()
            if e.which == ENTER_KEY
                if @check_completeness
                    echo "#{@loginuser},#{@password.value}"
                    if is_hide_users
                        @on_active(@account.value, @password.value)
                    else
                        @on_active(@loginuser, @password.value)
        )

        @login = create_element("button", "loginbutton", @element)
        if is_greeter
            @login.innerText = _("Log In")
        else
            @login.innerText = _("Unlock")

        @login.addEventListener("click", =>
            if @check_completeness
                echo "#{@loginuser},#{@password.value}"
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
        if is_hide_users
            if not @account.value
                @account.focus()
                return false
        if not @password.value
            @password.focus()
            return false
        return true

    password_error:(msg)->
        @password.style.color = "red"
        @password.value = msg
        @password.blur()
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
    userimg = null
    recognize = null
    username = null
    login_div = null

    constructor: (@id, name, @img_src,@type)->
        super
        @is_recognizing = false

        @element.setAttribute("type","li")
        @userinfo_li = create_element("li","userinfo_li",@element)
        @userinfo_li.id = "userinfo_li"
        userbase = create_element("div", "UserBase", @userinfo_li)
        img_div = create_element("div","img_div",userbase)
        userimg = create_img("userimg", @img_src, img_div)
        recognize = create_element("div", "recognize", userbase)
        recognize_h1 = create_element("h1", "", recognize)
        username = create_element("label", "UserName", recognize_h1)
        username.innerText = name

        login_div = create_element("div", "login_div", @userinfo_li)
        @login = new LoginEntry("login", @id,@type, (u, p)=>@on_verify(u, p))
        login_div.appendChild(@login.element)

        if is_greeter then @session = DCore.Greeter.get_user_session(@id)
        else @session = "deepin"

        @show_login()
        @face_login = DCore[APP_NAME].use_face_recognition_login(name)
        
        userinfo_list.push(@)

    draw_avatar: ->
        apply_animation(recognize,recognize_animation,"10s") if @face_login
        enable_detection(true) if @face_login

    stop_avatar:->
        clearInterval(draw_camera_id)
        draw_camera_id = null
        apply_animation(recognize,"","") if @face_login
        enable_detection(false) if @face_login
        #DCore[APP_NAME].cancel_detect()

    focus: ->
        DCore[APP_NAME].set_username(@id)

        @element.focus()

        if not @session? and @session in sessions
            de_menu.set_current(@session)
        else
            echo "#{@id} in focus invalid user session"

        @draw_camera()
        @draw_avatar()

    blur: ->
        # @loading?.destroy()
        # @loading = null
        @stop_avatar()


    show_login: ->
        if _current_user == @ and not @login
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
                if not DCore.Lock.need_password(@id)
                    @login.password.style.display = "none"
                    @login.password.value = "deepin"

    on_verify: (username, password)->
        #@loading = new Loading("loading")
        #@element.appendChild(@loading.element)

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
    
    normal_user_fail: (msg) ->
        echo "normal_user_fail"
        @login.password_error(msg)
        #apply_refuse_rotate(@element, 0.5)

    auth_failed: (msg) ->
        #echo "[User.auth_failed]"
        @stop_avatar()
        # message_tip?.remove()
        # message_tip = null
        # message_tip = new MessageTip(msg, user_ul.parentElement)
        @normal_user_fail(msg)


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
    # echo 'receive draw signal'
    clearInterval(draw_camera_id)
    draw_camera_id = null
    _current_user.draw_camera()
)

DCore.signal_connect("start-animation", ->
    # echo "receive start animation"
    _current_user.is_recognizing = true
    _remove_click_event?()
    _current_user.draw_avatar()
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
    message_tip.adjust_show_login()
)

