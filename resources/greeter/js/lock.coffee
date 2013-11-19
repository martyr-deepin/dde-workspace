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

    webview_ok:(_current_user)->
        DCore.Lock.webview_ok(_current_user.id)


    start_login_connect:(userinfo)->
        DCore.signal_connect("start-login", ->
            # echo "receive start login"
            # TODO: maybe some animation or some reflection.
            userinfo.is_recognizing = false
            DCore.Lock.try_unlock("")
        )

    keydown_listener:(userinfo)->
        document.body.addEventListener("keydown", (e) =>
            if e.which == ENTER_KEY
                if not userinfo.login_displayed
                    # if not userinfo.is_recognizing
                    if userinfo.face_login
                        DCore[APP_NAME].cancel_detect()
                        userinfo?.stop_animation()
                        userinfo.is_recognizing = false
                    userinfo.show_login()
                    message_tip?.remove()
                else
                    userinfo.login.on_active(user, userinfo.login.password.value)

            else if e.which == ESC_KEY
                userinfo.hide_login()
                message_tip?.remove()
        )

    get_username:->
        username = DCore.Lock.get_username()
        return username

    get_userimage:(username)->
        user_image = DCore.Lock.get_user_icon()
        if not user_image?
            try
                dbus = DCore.DBus.sys_object("com.deepin.passwdservice", "/", "com.deepin.passwdservice")
                user_image = dbus.get_user_fake_icon_sync(username)
            catch error
                user_image = "images/img01.jpg"
        return user_image




lock = new Lock()
username = lock.get_username()
userimage = lock.get_userimage(username)

user = new User()
#user.import_css("css/user.css")
user.new_switchuser()
user.new_userinfo_for_lock(username,userimage)
userinfo = user.get_userinfo_for_lock()
_current_user = user.get_current_user_for_lock()

lock.start_login_connect(userinfo)
lock.webview_ok(_current_user)
lock.keydown_listener(userinfo)

time = new Time()
time.show()
#time.import_css("css/time.css")
