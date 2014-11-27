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

class Welcome extends Page
    constructor:(@id)->
        super
        echo "welcome #{@id}"
        inject_css(@element,"css/welcome.css")
        DEFAULT_BG = "/usr/share/backgrounds/default_background.jpg"
        @element.style.backgroundImage = "url(#{DEFAULT_BG})"
        @element.style.webkitBoxOrient = "vertical"
        @session = new Session()

        @logo_wel = create_element("div","logo_wel",@element)
        @logo_img = create_img("logo_img","",@logo_wel)
        @logo_img.src = "#{@img_src}/logo.png"
        @welcome_text = create_element("div","welcome_text",@logo_wel)
        @welcome_text.textContent = _("Welcome to use Deepin Operating System")

        @readying = create_element("div","readying",@element)
        @readying.innerText = _("Prepare for operation ...")

        interval_switch = setInterval(=>
            if @session.getStage() < @session.STAGE.SessionStageCoreEnd then return
            clearInterval(interval_switch)
            @prepare()
        ,200)

    show_signal_cb: =>
        @launcher.hide()
        try
            @launcher.show_signal_disconnect()
        catch e
            console.debug "#{e}"

    prepare : =>
        try
            @launcher = new Launcher()
            @launcher.show_signal(@show_signal_cb)
            @launcher.show()
        catch e
            console.debug "#{e}"
        finally
            setTimeout(=>
                @show_signal_cb()
                guide?.switch_page(@,"Start")
            ,2000)
