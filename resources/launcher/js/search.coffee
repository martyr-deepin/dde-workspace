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

s_box = $('#s_box')

init_search_box = ->
    s_box.setAttribute("placeholder", _("Type to search..."))

    $("#search").addEventListener('click', (e)->
        if e.target == s_box
            e.stopPropagation()
    )

    s_box.addEventListener('input', s_box.blur())

    DCore.signal_connect("im_commit", (info)->
        s_box.value += info.Content
        search()
    )

do_search = ->
    ret = []
    key = s_box.value.toLowerCase().trim()

    for k,v of applications
        if key == ""
            ret.push(
                "value": k
                "weight": 0
            )
        else if (weight = DCore.Launcher.is_contain_key(v.core, key))
            ret.push(
                "value": k
                "weight": weight
            )

    ret.sort((lhs, rhs) -> rhs.weight - lhs.weight)
    ret = (item.value for item in ret)

    return update_items(ret)

search = do ->
    _search_id = null
    ->
        clearTimeout(_search_id)
        _search_id = setTimeout(->
            grid_show_items(update_items(do_search()))
        , 20)


cursor = create_element("span", "cursor", document.body)
cursor.innerText = "|"
