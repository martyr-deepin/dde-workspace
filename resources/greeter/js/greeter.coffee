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
        DCore.Greeter.webview_ok(_current_user.id)

    start_login_connect:(_current_user)->
        DCore.signal_connect("start-login", ->
            # echo "receive start login"
            # TODO: maybe some animation or some reflection.
            _current_user.is_recognizing = false
            DCore.Greeter.start_session(_current_user.id, "", de_menu.get_current())
        )

    mousewheel_listener:(_current_user)->
        document.body.addEventListener("mousewheel", (e) =>
            if not is_volume_control
                if e.wheelDelta >= 120 then _current_user?.animate_next()
                else if e.wheelDelta <= -120 then _current_user?.animate_prev()
        )


    keydown_listener:(_current_user)->
        document.body.addEventListener("keydown", (e)=>
            if e.which == UP_ARROW
                # echo "prev"
                _current_user?.animate_next()

            else if e.which == DOWN_ARROW
                # echo "next"
                _current_user?.animate_prev()

            else if e.which == ENTER_KEY
                #echo "enter"
                # if not _current_user?.is_recognizing
                if _current_user?.face_login
                    _current_user?.is_recognizing = false
                    DCore[APP_NAME].cancel_detect()
                    _current_user?.stop_animation()
                _current_user?.show_login()
                message_tip?.remove()

        )



document.body.style.height = window.innerHeight
document.body.style.width = window.innerWidth

greeter = new Greeter()

desktopmenu = new DesktopMenu($("div_desktop"))
desktopmenu.new_desktop_menu()


user = new User()
$("#div_users").appendChild(user.element)
user.roundabout_animation()

userinfo = user.get_current_userinfo()
_current_user = user.get_current_userinfo()

greeter.start_login_connect(userinfo)
greeter.webview_ok(_current_user)
greeter.keydown_listener(userinfo)
greeter.mousewheel_listener(_current_user)

timedate = new TimeDate()
$("#div_time").appendChild(timedate.element)
timedate.show()



$("#div_power").title = _("ShutDown")
powermenu = new PowerMenu($("#div_power"))
powermenu.new_power_menu()


version = new Version()
$("#div_version").appendChild(version.element)

