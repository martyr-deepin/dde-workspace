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

is_show_hidden_icons = false
_show_hidden_icons = (is_shown) ->
    if is_shown == is_show_hidden_icons
        return
    is_show_hidden_icons = is_shown

    Item.display_temp = false
    if is_shown
        hiddenIcons.show()
    else
        hiddenIcons.hide()

path = localStorage.getItem("bg")
setBackground(path)
setTimeout(->
    p = daemon.GetBackgroundPict_sync()
    if p != path
        setBackground(p)
, 1000)

init_all_applications = ->
    # get all applications and sort them by name
    _all_items = daemon.ItemInfos_sync(CATEGORY_ID.ALL)
    autostartList = startManager.AutostartList_sync()

    for core in _all_items
        createItem(core, autostartList)


init_all_applications()
echo "load all applications done"

favor = new FavorPage()
echo 'load favor done'

searchBar = new SearchBar()
echo "create search bar done"

switcher = new Switcher()
echo "load switcher done"

categoryInfos = daemon.CategoryInfos_sync()
echo "get category infos done"

categoryBar = new CategoryBar(categoryInfos)
echo "load category bar done"

categoryList = new CategoryList(categoryInfos)
echo "load category list done"

hiddenIcons = new HiddenIcons()
hiddenIcons.hide()
echo "load hidden icons done"

bind_events()
echo "bind event done"

selector = new Selector()
selector.container($("#favor"))
echo "create selector done"

DCore.Launcher.webview_ok()
echo "webview ok"
DCore.Launcher.test()
