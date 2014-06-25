#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2011 ~ 2013 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
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

class Greeter extends Widget

    constructor:->
        super
        echo "Greeter"
        document.body.appendChild(@element)

    webview_ok:(_current_user)->
        DCore.Greeter.webview_ok(_current_user.id) if hide_face_login

    start_login_connect:(_current_user)->
        DCore.signal_connect("start-login", ->
            # echo "receive start login"
            # TODO: maybe some animation or some reflection.
            _current_user.is_recognizing = false
            DCore.Greeter.start_session(_current_user.id, _current_user.password, _current_user.session)
        )

    mousewheel_listener:(user)->
        document.body.addEventListener("mousewheel", (e) =>
            if e.wheelDelta >= 120 then user?.switchtonext_userinfo()
            else if e.wheelDelta <= -120 then user?.switchtoprev_userinfo()
        )


    keydown_listener:(e,user)->
        echo "greeter keydown_listener"
        if e.which == LEFT_ARROW
            user?.switch_userinfo("next")
        else if e.which == RIGHT_ARROW
            user?.switch_userinfo("prev")

    isOnlyOneSession:->
        @sessions = DCore.Greeter.get_sessions()
        @is_one_session = false
        if @sessions.length == 0
            echo "your system has no session!!!"
            new NoSessionMessage()
        else if @sessions.length == 1 then @is_one_session = true
        return @is_one_session


greeter = new Greeter()
greeter.isOnlyOneSession()

div_users = create_element("div","div_users",greeter.element)
div_users.setAttribute("id","div_users")
div_version = create_element("div","div_version",greeter.element)
div_version.setAttribute("id","div_version")
div_desktop = create_element("div","div_desktop",greeter.element)
div_desktop.setAttribute("id","div_desktop")
div_power = create_element("div","div_power",greeter.element)
div_power.setAttribute("id","div_power")
div_userchoose = create_element("div","div_userchoose",greeter.element)
div_userchoose.setAttribute("id","div_userchoose")

desktopmenu = null
if greeter.sessions.length > 1
    desktopmenu = new DesktopMenu($("#div_desktop"))
    desktopmenu.new_desktop_menu()

user = new User()
$("#div_users").appendChild(user.element)
user.new_userinfo_for_greeter()

left = (screen.width  - $("#div_users").clientWidth) / 2
top = (screen.height  - $("#div_users").clientHeight) / 2 * 0.8
$("#div_users").style.left = "#{left}px"
$("#div_users").style.top = "#{top}px"

userinfo = user.get_current_userinfo()
_current_user = user.get_current_userinfo()

greeter.start_login_connect(userinfo)
greeter.webview_ok(_current_user) if hide_face_login

version = new Version()
$("#div_version").appendChild(version.element)

powermenu = null
powermenu = new PowerMenu($("#div_power"))
powermenu.new_power_menu()

usermenu = null
#user.prev_next_userinfo_create() if user.userinfo_all.length > 1
if user.userinfo_all.length > 1
    usermenu = new UserMenu($("#div_userchoose"),user.userinfo_all)
    usermenu.new_user_menu()
    if _current_user.is_logined then usermenu.menuShow()
else
    $("#div_userswitch").style.display = "none"
    $("#div_desktop").style.right = "11em"

document.body.addEventListener("keydown",(e)->
    try
        if is_greeter
            echo "greeter keydown"
            powermenu?.keydown_listener(e)
            desktopmenu?.keydown_listener(e)
            if user.userinfo_all.length < 2 then return
            usermenu?.keydown_listener(e)
            if powermenu.ComboBox.menu.is_hide()
                if not desktopmenu?
                    greeter.keydown_listener(e,user)
                else if desktopmenu.ComboBox.menu.is_hide()
                    greeter.keydown_listener(e,user)
    catch e
        echo "#{e}"
)
