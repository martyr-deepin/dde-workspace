#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#             LongWei <yilang2007lw@gmail.com>
#                     <snyh@snyh.org>
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

class Message extends Widget
    
    constructor: (@id)->
        super
        @text = []
        @text_li = []

    hide:->
        @element.style.display = "none"

    show:->
        @element.style.display = "block"

    title_text: (@title ,@text) ->

    frame_build: ->
        @element.style.width = WindowWidth / 2
        @title_p = create_element("p","title_p",@element)
        @title_p.textContent = @title
        @title_ol = create_element("ol","title_ol",@title_p)
        for text,i in @text
            echo text
            @text_li[i] = create_element("li","text_li",@title_ol)
            jQuery(@text_li).attr("title",text)
            #@text_li.title = text
    
    setZIndex: (zIndex = 65530) ->
        @element.style.position = "relative"
        @element.style.zIndex = "#{zIndex}"

class NoSessionMessage

    constructor: ->
        
        @title = _("No desktop sessions available.\n
            You can try the following steps and install the Deepin Desktop Environment.")
        @text = []
        @text = [
            _("Switch to a virtual console.\n
                \tYou can do this by pressing the Ctrl + Alt + F1~F6 key combination (press and hold \"Ctrl\" and \"Alt\" at the same time and press the \"F(x)\" key corresponding to the TTY you want to switch to. For example, press  \"F1\" to switch to TTY 1 or \"F2\" to switch to TTY 2."),
            _("Install Deepin Desktop Environment:\n
                \t$ sudo apt-get install deepin-desktop-Environment
                "),
            _("Restart your system:\n
                \t$ sudo reboot")
        ]
        
        @message = new Message("NoSession")
        @message.title_text(@title,@text)
        @message.frame_build()
        @message.setZIndex(65530)
        @message.show()
        document.body.appendChild(@message.element)
        


