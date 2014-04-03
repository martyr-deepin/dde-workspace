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
_ANIMATE_TIMEOUT_ID = -1

class Greeter extends Widget

    constructor:->
        super
        echo "Greeter"


    webview_ok:(_current_user)->
        DCore.Greeter.webview_ok(_current_user.id) if hide_face_login

    start_login_connect:(_current_user)->
        DCore.signal_connect("start-login", ->
            # echo "receive start login"
            # TODO: maybe some animation or some reflection.
            _current_user.is_recognizing = false
            DCore.Greeter.start_session(_current_user.id, "", de_menu.get_current())
        )

    mousewheel_listener:(user)->
        document.body.addEventListener("mousewheel", (e) =>
            if not is_volume_control
                if e.wheelDelta >= 120 then user?.switchtonext_userinfo()
                else if e.wheelDelta <= -120 then user?.switchtoprev_userinfo()
        )


    keydown_listener:(e,user)->
        echo "keydown_listener"
        echo user
        if e.which == LEFT_ARROW
            user?.switchtonext_userinfo()
        else if e.which == RIGHT_ARROW
            user?.switchtoprev_userinfo()

    setBodyWallpaper:(wallpaper)->
        echo "setBodyWallpaper:#{wallpaper}"
        _b = document.body
        
        _b.style.height = window.innerHeight
        _b.style.width = window.innerWidth
        switch wallpaper
            when "sky_move"
                _b.style.backgroundImage = "url(js/skyThree/sky3.jpg)"
                inject_js("js/skyThree/sky.js")
            when "sky_static"
                _b.style.backgroundImage = "url(js/skyThree/sky3.jpg)"
            when "color"
                _b.style.backgroundImage = "url(images/background1.jpg)"
            else
                inject_js("js/skyThree/Three.js")
                inject_js("js/skyThree/sky.js")

greeter = new Greeter()
greeter.setBodyWallpaper("sky_move")

desktopmenu = new DesktopMenu($("#div_desktop"))
desktopmenu.new_desktop_menu()


user = new User()
$("#div_users").appendChild(user.element)
user.isSupportGuest()
user.new_userinfo_for_greeter()
user.prev_next_userinfo_create() if user.userinfo_all.length > 1

left = (screen.width  - $("#div_users").clientWidth) / 2
top = (screen.height  - $("#div_users").clientHeight) / 2 * 0.8
$("#div_users").style.left = "#{left}px"
$("#div_users").style.top = "#{top}px"

userinfo = user.get_current_userinfo()
_current_user = user.get_current_userinfo()

greeter.start_login_connect(userinfo)
greeter.webview_ok(_current_user) if hide_face_login
#greeter.mousewheel_listener(user)


version = new Version()
$("#div_version").appendChild(version.element)

powermenu = new PowerMenu($("#div_power"))
powermenu.new_power_menu()



document.body.addEventListener("keydown",(e)->
    if is_greeter
        if $("#power_menuchoose") or $("#desktop_menuchoose")
            if $("#power_menuchoose").style.display isnt "none"
                powermenu.keydown_listener(e)
            else if $("#desktop_menuchoose").style.display isnt "none"
                desktopmenu.keydown_listener(e)
            else if is_greeter and greeter and user
                greeter.keydown_listener(e,user)
        else if is_greeter and greeter and user
            greeter.keydown_listener(e,user)
    else
        if $("#power_menuchoose") and $("#power_menuchoose").style.display isnt "none"
                powermenu.keydown_listener(e)
        else if audio_play_status
            mediacontrol.keydown_listener(e)
        else if is_greeter and greeter and user
            greeter.keydown_listener(e,user)
)
