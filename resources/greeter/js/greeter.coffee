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

get_user_image = (user) ->
    try
        user_image = DCore.Greeter.get_user_icon(user)
    catch error
        echo error

    if not user_image?
        try
            user_image = DCore.DBus.sys_object("com.deepin.passwdservice", "/", "com.deepin.passwdservice").get_user_fake_icon_sync(user)
        catch error
            user_image = "images/guest.jpg"

    return user_image

if DCore.Greeter.is_hide_users()
    u = new UserInfo("*other", "", "images/huser.jpg")
    roundabout.appendChild(u.li)
    Widget.look_up("*other").element.style.paddingBottom = "5px"
    u.focus()
else
    users = DCore.Greeter.get_users()
    for user in users
        if user == DCore.Greeter.get_default_user()
            user_image = get_user_image(user)
            u = new UserInfo(user, user, user_image)
            roundabout.appendChild(u.li)
            u.focus()

    for user in users
        if user == DCore.Greeter.get_default_user()
            echo "already append default user"
        else
            user_image = get_user_image(user)
            u = new UserInfo(user, user, user_image)
            roundabout.appendChild(u.li)

    if DCore.Greeter.is_support_guest()
        u = new UserInfo("guest", _("guest"), "images/guest.jpg")
        roundabout.appendChild(u.li)
        if DCore.Greeter.is_guest_default()
            u.focus()

userinfo_list[0]?.focus()

####the _counts must put before any animate of roundabout####
_counts = roundabout.childElementCount
_ANIMATE_TIMEOUT_ID = -1

document.body.addEventListener("mousewheel", (e) =>
    clearTimeout(_ANIMATE_TIMEOUT_ID)
    _ANIMATE_TIMEOUT_ID = -1

    if e.wheelDelta >= 120
        #echo "scroll to prev"
        _ANIMATE_TIMEOUT_ID = setTimeout( ->
            _current_user?.animate_prev()
        , 200)

    if e.wheelDelta <= -120
        #echo "scroll to next"
        _ANIMATE_TIMEOUT_ID = setTimeout( ->
            _current_user?.animate_next()
        ,200)
)

document.body.addEventListener("keydown", (e)=>
    if e.which == LEFT_ARROW
        # echo "prev"
        _current_user?.animate_prev()

    else if e.which == RIGHT_ARROW
        # echo "next"
        _current_user?.animate_next()

    else if e.which == ENTER_KEY
        #echo "enter"
        if not _current_user?.is_recognizing
            _current_user?.show_login()
            message_tip?.remove()

    else if e.which == ESC_KEY
        #echo "esc"
        _current_user?.hide_login()
        message_tip?.remove()
)

if roundabout.children.length <= 2
    roundabout.style.width = "0"
    #Widget.look_up(roundabout.children[0].children[0].getAttribute("id"))?.show_login()
    userinfo_list[0]?.focus()
    if not userinfo_list[0].face_login
        userinfo_list[0]?.show_login()

l = (screen.width  - roundabout.clientWidth) / 2
roundabout.style.left = "#{l}px"

jQuery("#roundabout").drag("start", (ev, dd) ->
    _current_user?.hide_login()
    _drag_flag = true
, {distance:100}
)

jQuery("#roundabout").drag("end", (ev, dd) ->
    _current_user?.animate_near()
)

DCore.signal_connect("start-login", ->
    # echo "receive start login"
    # TODO: maybe some animation or some reflection.
    _current_user.is_recognizing = false
    DCore.Greeter.start_session(_current_user.id, "", de_menu.get_current())
)

# if _current_user.face_login
#     message_tip = new MessageTip(SCANNING_TIP, roundabout.parentElement)

DCore.Greeter.webview_ok(_current_user.id)

