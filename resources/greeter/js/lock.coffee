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

user = DCore.Lock.get_username()

user_image = DCore.Lock.get_user_icon()

if not user_image?
    try
        user_image = DCore.DBus.sys_object("com.deepin.passwdservice", "/", "com.deepin.passwdservice").get_user_fake_icon_sync(user)
    catch error
        user_image = "images/img01.jpg"

try
    is_livecd = DCore.DBus.sys_object("com.deepin.dde.lock", "/com/deepin/dde/lock", "com.deepin.dde.lock").IsLiveCD_sync(user)
catch error
    is_livecd = false

if not is_livecd
    s = new SwitchUser("switchuser")
    $("#desktop_power").appendChild(s.element)

u = new UserInfo(user, user, user_image)

div_users.appendChild(u.li)
_current_user = u

u.focus()
if not u.face_login
    u.show_login()

document.body.addEventListener("keydown", (e) =>
    if e.which == ENTER_KEY
        if not u.login_displayed
            # if not u.is_recognizing
            if u.face_login
                DCore[APP_NAME].cancel_detect()
                u?.stop_animation()
                u.is_recognizing = false
            u.show_login()
            message_tip?.remove()
        else
            u.login.on_active(user, u.login.password.value)

    else if e.which == ESC_KEY
        u.hide_login()
        message_tip?.remove()
)

if div_users.children.length <= 2
    div_users.style.width = "0"
    l = (screen.width  - div_users.clientWidth) / 2
    div_users.style.left = "#{l}px"
    user = Widget.look_up(div_users.children[0].children[0].getAttribute("id"))
    if not user?.face_login
        user?.show_login()


DCore.signal_connect("start-login", ->
    # echo "receive start login"
    # TODO: maybe some animation or some reflection.
    u.is_recognizing = false
    DCore.Lock.try_unlock("")
)

# if _current_user.face_login
#     message_tip = new MessageTip(SCANNING_TIP, div_users.parentElement)

DCore.Lock.webview_ok(_current_user.id)

