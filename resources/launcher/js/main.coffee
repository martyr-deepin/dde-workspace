#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#              2013 ~ Lee Liqiang
#
#Author:      snyh <snyh@snyh.org>
#Maintainer:  Lee Liqiang <liliqiang@linuxdeepin.com>
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


# key: id of app (md5 basenam of path)
# value: Item class
applications = {}

# key: id of app
# value: Item class
uninstalling_apps = {}


reset = ->
    selected_category_id = CATEGORY_ID.ALL
    clean_search_bar()
    # s_box.focus()
    hidden_icons.save()
    _show_hidden_icons(false)
    get_first_shown()?.scroll_to_view()
    if Item.hover_item_id
        event = new Event("mouseout")
        Widget.look_up(Item.hover_item_id).element.dispatchEvent(event)


is_show_hidden_icons = false
_show_hidden_icons = (is_shown) ->
    if is_shown == is_show_hidden_icons
        return
    is_show_hidden_icons = is_shown

    Item.display_temp = false
    if is_shown
        hidden_icons.show()
    else
        hidden_icons.hide()


init_all_applications = ->
    # get all applications and sort them by name
    _all_items = daemon.ItemInfos_sync(CATEGORY_ID.ALL)

    frag = document.createDocumentFragment()
    for core in _all_items
        path = core[0]
        name = core[1]
        id = core[2]
        icon = core[3]
        applications[id] = new Item(id, name, path, icon)
        frag.appendChild(applications[id].searchElement)
    $("#searchResult").appendChild(frag)


search_bar = new SearchBar()
init_all_applications()
category_infos = daemon.CategoryInfos_sync()
category_bar = new CategoryBar(category_infos)
category_list = new CategoryList(category_infos)
hidden_icons = new HiddenIcons()
hidden_icons.hide()
bind_events()
DCore.Launcher.webview_ok()
DCore.Launcher.test()

