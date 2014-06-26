#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 bluth
#
#encoding: utf-8
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
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

class Language extends Widget

    constructor:->
        super
        #inject_js("js/jquery/jquery.min.js")
        #inject_js("js/jquery/jquery.nicescroll.js")
        inject_css(_b,"css/language.css")
        @get_lang_list()
        @boxscroll_create()

    launch_check: ->
        APP_NAME = null
        try
            DCore.Greeter.get_date()
            APP_NAME = "Greeter"
        catch error
            APP_NAME = "Lock"
         
        is_livecd = false
        try
            is_livecd = DCore[APP_NAME].is_livecd()
        catch
            is_livecd = false
        
        return (is_livecd and APP_NAME is "Greeter")
        
    get_lang_list: ->
        @lang_list = {}

    select_lang: (name) ->
        #TODO:update /etc/default/locale and command locale-gen
        @username = "ycl"
        @password = "1"
        @session = "deepin"
        document.body.cursor = "wait"
        DCore.Greeter.start_session(@username, @password, @session)

    boxscroll_create: ->
        @boxscroll = $("#boxscroll")
        @ul = create_element("ul","",@boxscroll)
        for lang,i in @lang_list
            @li[i] = create_element("li","",@ul)
            @a[i] = create_element("a","",@li[i])
            @a[i].title = lang.Name
            @a[i].innerText = lang.Locale
        setTimeout(=>
            @select_lang("zh_CN")
        ,3000)

new Language()
