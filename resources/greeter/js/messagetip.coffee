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
class MessageTip
    constructor:(text, @parent)->
        @message_tip = null
        @message_tip = create_element("div", "failed-tip", @parent)
        @message_tip.appendChild(document.createTextNode(text))
        @message_tip.style.top = "#{.15 * window.innerHeight + 310}px"

    adjust_show_login: ->
        @message_tip.style.top = "#{.15 * window.innerHeight + 390}px"

    remove: =>
        if @message_tip
            @parent.removeChild(@message_tip)
            @message_tip = null
