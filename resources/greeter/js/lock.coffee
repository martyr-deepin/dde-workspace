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


enableZoneDetect = (enable) ->
    echo "enableZoneDetect :#{enable}"
    ZONE = "com.deepin.daemon.Zone"
    try
        zoneDBus = DCore.DBus.session(ZONE) if not zoneDBus?
        zoneDBus?.EnableZoneDetected_sync(enable)
    catch e
        echo "zoneDBus #{ZONE} error : #{e}"


class Lock extends Widget

    constructor:->
        super
        echo "Lock"
        inject_css(_b,"css/lock.css")
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

_b = document.body

div_users = create_element("div","div_users",_b)
div_users.setAttribute("id","div_users")
div_keyboard = create_element("div","div_keyboard",_b)

user = new User("lock_users",div_users)
user.new_userinfo_for_lock()
userinfo = user.get_current_userinfo()
_current_user = user.get_current_userinfo()


lock.start_login_connect(userinfo)
lock.webview_ok(_current_user) if hide_face_login

div_time = create_element("div","div_time",_b)
div_time.setAttribute("id","div_time")
timedate = new TimeDate()
$("#div_time").appendChild(timedate.element)
timedate.show()


powermenu = null
div_power = create_element("div","div_power",_b)
div_power.setAttribute("id","div_power")
powermenu = new PowerMenu($("#div_power"))
powermenu.new_power_menu()


mediacontrol = new MediaControl()
div_media_control = null
if mediacontrol.check_launched()
    div_media_control = create_element("div","div_media_control",_b)
    div_media_control.setAttribute("id","div_media_control")
    mediacontrol.create_mediacontrol_div()
    $("#div_media_control").appendChild(mediacontrol.element)


if not is_livecd
    div_switchuser = create_element("div","div_switchuser",_b)
    div_switchuser.setAttribute("id","div_switchuser")
    s = new SwitchUser()
    s.button_switch()
    $("#div_switchuser").appendChild(s.element)

set_element_pos = ->
    left = (screen.width  - 250) / 2
    top = (screen.height  - 180) / 2 * 0.8
    div_users?.style.left = left
    div_users?.style.top = top
    div_keyboard?.style.left = left + 10
    div_keyboard?.style.top = top + 180 + 10

    div_time?.style.bottom = "4em"
    div_time?.style.left = "3em"

    div_switchuser?.style.bottom = "3.5em"
    div_switchuser?.style.right = "10em"

    div_power?.style.bottom = "3.5em"
    div_power?.style.right = "3em"

    div_media_control?.style.bottom = "3.5em"
    div_media_control?.style.right = "19em"

    menuchoose = jQuery(".MenuChoose")
    for menu in menuchoose
        w = Widget.look_up(menu.id)
        w.setPos()

set_element_pos()

body_keydown_listener((e)->
    mediacontrol?.keydown_listener(e) if div_media_control?
)
DCore.Lock.emit_webview_ok()

DCore.signal_connect("leave-notify", (area) ->
    document.body.style.width = area.width
    document.body.style.height = area.height
    set_element_pos()
)
