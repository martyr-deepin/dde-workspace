#Copyright (c) 2012 ~ 2014 Deepin, Inc.
#              2012 ~ 2014 snyh
#
#Author:      snyh <snyh@snyh.org>
#             Cole <phcourage@gmail.com>
#             bluth <yuanchenglu001@gmail.com>
#
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

class Folder extends DesktopEntry
    set_icon : (src = null) =>
        if src == null
            icon = DCore.get_theme_icon("folder", D_ICON_SIZE_NORMAL)
        else
            icon = src
        super(icon)


    do_drop : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            tmp_list = []
            for file in evt.dataTransfer.files
                if (e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, "")))?
                    tmp_list.push(e)
            if tmp_list.length > 0 then DCore.DEntry.move(tmp_list, @_entry, true)
        return


    do_dragenter : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragover : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return


    do_dragleave : (evt) ->
        super
        if _IS_DND_INTERLNAL_(evt) and @selected
        else
            evt.dataTransfer.dropEffect = "move"
        return

