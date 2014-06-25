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
        document.body.appendChild(@element)
        power = {"lock":false,"value":null}
        localStorage.setObject("shutdown_from_lock",power)
        enableZoneDetect(false)

    webview_ok:(_current_user)->
        DCore.Lock.webview_ok(_current_user.id) if hide_face_login

    start_login_connect:(userinfo)->
        DCore.signal_connect("start-login", ->
            echo "receive start login"
            # TODO: maybe some animation or some reflection.
            userinfo.is_recognizing = false
            DCore.Lock.try_unlock("")
        )




lock = new Lock()

is_guest = DCore.Lock.is_guest()


div_users = create_element("div","div_users",lock.element)
div_users.setAttribute("id","div_users")
div_time = create_element("div","div_time",lock.element)
div_time.setAttribute("id","div_time")
div_power = create_element("div","div_power",lock.element)
div_power.setAttribute("id","div_power")
div_media_control = create_element("div","div_media_control",lock.element)
div_media_control.setAttribute("id","div_media_control")
div_switchuser = create_element("div","div_switchuser",lock.element)
div_switchuser.setAttribute("id","div_switchuser")

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



powermenu = null
powermenu = new PowerMenu($("#div_power"))
powermenu.new_power_menu()


audio_play_status = null
is_volume_control = null
try
    audioplay = new AudioPlay()
    audio_play_status = audioplay.get_launched_status()
    if audio_play_status
        if audioplay.getTitle() is undefined then audio_play_status = false
    is_volume_control = false
    echo "audio_play_status:#{audio_play_status}"
catch e
    echo "#{e}"
    audio_play_status = false
    is_volume_control = false

mediacontrol = null
if audio_play_status
    mediacontrol = new MediaControl()
    $("#div_media_control").appendChild(mediacontrol.element)

 #-------------------------------------------

if not is_livecd
    s = new SwitchUser()
    s.button_switch()
    $("#div_switchuser").appendChild(s.element)



document.body.addEventListener("keydown",(e)->
    try
        if !is_greeter
            if powermenu?.ComboBox.menu.is_hide()
                mediacontrol?.keydown_listener(e)
            else
                powermenu?.keydown_listener(e)
    catch e
        echo "#{e}"
)

