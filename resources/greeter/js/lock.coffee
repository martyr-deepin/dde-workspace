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

class Lock extends Widget

    constructor:->
        super
        echo "Lock"
        power = {"lock":false,"value":null}
        localStorage.setObject("shutdown_from_lock",power)
    
    webview_ok:(_current_user)->
        DCore.Lock.webview_ok(_current_user.id) if hide_face_login


    start_login_connect:(userinfo)->
        DCore.signal_connect("start-login", ->
            echo "receive start login"
            # TODO: maybe some animation or some reflection.
            userinfo.is_recognizing = false
            DCore.Lock.try_unlock("")
        )


    setBodyWallpaper:(wallpaper)->
        echo "setBodyWallpaper:#{wallpaper}"
        _b = document.body
        _b.style.height = window.innerHeight
        _b.style.width = window.innerWidth
        switch wallpaper
            when "sky_move"
                _b.style.backgroundImage = "url(js/skyThree/sky3.jpg)"
                inject_js("js/skyThree/Three.js")
                inject_js("js/skyThree/sky.js")
            when "sky_static"
                _b.style.backgroundImage = "url(js/skyThree/sky3.jpg)"
            when "color"
                _b.style.backgroundImage = "url(images/background1.jpg)"
            else
                inject_js("js/skyThree/Three.js")
                inject_js("js/skyThree/sky.js")

    dbusPowerManager:->
        try
            POWER = "com.deepin.daemon.Power"
            PowerManager = DCore.DBus.session(POWER)
            PowerManager.StartDim() if PowerManager?
            echo "PowerManager.StartDim()" if PowerManager?
        catch e
            echo "POWER:ERROR:#{e}"


lock = new Lock()
lock.setBodyWallpaper("sky_static")
lock.dbusPowerManager()

user = new User()
$("#div_users").appendChild(user.element)
user.new_userinfo_for_lock()
left = (screen.width  - $("#div_users").clientWidth) / 2
top = (screen.height  - $("#div_users").clientHeight) / 2 * 0.8
$("#div_users").style.left = "#{left}px"
$("#div_users").style.top = "#{top}px"

userinfo = user.get_current_userinfo()
_current_user = user.get_current_userinfo()

lock.start_login_connect(userinfo)
lock.webview_ok(_current_user) if hide_face_login

timedate = new TimeDate()
$("#div_time").appendChild(timedate.element)
timedate.show()



#$("#div_power").title = _("ShutDown")
powermenu = new PowerMenu($("#div_power"))
powermenu.new_power_menu()


if audio_play_status
    mediacontrol = new MediaControl()
    $("#div_media_control").appendChild(mediacontrol.element)


if not is_livecd
    s = new SwitchUser()
    s.button_switch()
    $("#div_switchuser").appendChild(s.element)


document.body.addEventListener("keydown",(e)->
    echo "keydown:#{e.which}"
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
