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
shutdown = null

frame_click = false
option = ["lock","suspend","logout","restart","shutdown"]
option_text = [_("Lock"),_("Suspend"),_("Log out"),_("Restart"),_("Shut down")]
message_text = [
    _("The system will be locked in:"),
    _("The system will be suspended in:"),
    _("You will be automatically logged out in:"),
    _("The system will restart in:"),
    _("The system will shut down in:")
]

timeId = null

destory_all = ->
    clearInterval(timeId) if timeId
    DCore.Shutdown.quit()


confirm_ok = (i)->
    destory_all()
    echo option[i]
    power_fuc(option[i])