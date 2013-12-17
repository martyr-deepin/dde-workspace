#Copyright (c) 2012 ~ 2013 Deepin, Inc.
#              2012 ~ 2013 bluth
#
#encoding: utf-8
#Author:      bluth <\yuanchenglu@linuxdeepin.com>
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

confirmdialog = null
powerchoose = null

frame_click = false
option = ["lock","suspend","logout","restart","shutdown"]
option_text = [_("Lock"),_("Suspend"),_("Log out"),_("Restart"),_("Shut down")]
message_text = [
    _("The system will be locked in %1 seconds."),
    _("The system will be suspended in %1 seconds."),
    _("You will be automatically logged out in %1 seconds."),
    _("The system will restart in %1 seconds."),
    _("The system will shut down in %1 seconds.")
]

timeId = null

destory_all = ->
    clearInterval(timeId) if timeId
    DCore.Shutdown.quit()


confirm_ok = (i)->
    #destory_all()
    echo option[i]
    switch option[i]
        when "lock" then destory_all()
        when "suspend" then destory_all()
    clearInterval(timeId) if timeId
    power_func(option[i])

document.body.style.height = window.innerHeight
document.body.style.width = window.innerWidth
#DCore.signal_connect("draw_background", (info)->
    #echo "draw_background:url(#{info.path})"
    #document.body.style.backgroundImage = "url(#{info.path})"
#)
