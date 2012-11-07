#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#Maintainer:  snyh <snyh@snyh.org>
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

preview_current_id = 0
_interval_id = 0
_hide_timeout_id = 0

#gloabl variable and function

preview_disactive = (timeout) ->
    clearTimeout(_hide_timeout_id)
    _hide_timeout_id = setTimeout(->
                    clearInterval(_interval_id)
                    _ctx.clearRect(0, 0, 300, 200)
                    DCore.Dock.close_show_temp()
                    preview_current_id = 0
                timeout)

preview_active = (id, offset) ->
            _preview.style.left = offset+"px"
            preview_current_id = id
            clearInterval(_interval_id)
            _ctx.clearRect(0, 0, 300, 200)

            preview_disactive(3000)
            _update_preview()
            _interval_id = setInterval(_update_preview, 600)
            DCore.Dock.show_temp_region(offset, 0, 300, 200)

preview_close_window = ->
    preview_disactive(80)


#moudle local stub

_preview = $('#preview')
_ctx = _preview.getContext('2d')



_update_preview = ->
    s = DCore.Dock.fetch_window_preview(preview_current_id, 300, 200)
    img = _ctx.getImageData(0, 0, s.width, s.height)
    for v,i in s.data
        img.data[i] = v
    _ctx.putImageData(img, 0, 0)

_preview.addEventListener('mouseover', ->
    clearTimeout(_hide_timeout_id)
)
_preview.addEventListener('mouseout', ->
    preview_disactive(1000)
)

DCore.signal_connect("leave-notify", preview_close_window)
