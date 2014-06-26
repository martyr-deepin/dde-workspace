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
        inject_js("jquery/jquery.nicescroll.js")
        inject_css(_b,"css/language.css")

    launch_check: ->
        return (is_livecd and APP_NAME is "Greeter")

    get_lang_list: ->
        @lang_list = {}

    select_lang: (lang) ->
        #TODO:update /etc/default/locale and command locale-gen
        @username = "deepin"
        @password = "deepin"
        @session = "deepin"
        document.body.cursor = "wait"
        DCore.Greeter.start_session(@username, @password, @session)

    boxscroll_create: ->
        nicesx = $("#boxscroll").niceScroll({touchbehavior:false,cursorcolor:"#fff",cursoropacitymax:0.6,cursorwidth:8})
        
        @wrap = create_element("div","wrap",_b)
        @wrap.setAttribute("onselectstart","return false")
        @wrap.setAttribute("style","-moz-user-select:none")

