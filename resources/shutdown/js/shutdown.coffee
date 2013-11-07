#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      Cole <phcourage@gmail.com>
#Maintainer:  Cole <phcourage@gmail.com>
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


class ShutDown extends Widget
	option = ["lock","suspend","logout","restart","shutdown"]
    constructor: (@id)->
        super
        @frame = create_element("div", "frame", @element)
        
        opt = []
        img_url = []
        opt_img = []
        text = []
        opt_text = []
        
        for tmp ,i in option
            opt[i] = create_element("div","opt",@frame)
            img_url[i] = "img/normal/#{option[i]}.png"
            opt_img[i] = create_img("opt_img",img_url[i],opt[i])
            text[i] = _(option[i])
            opt_text[i] = create_element("a","opt_text",opt[i])
            opt_text[i].textContext = text[i]


