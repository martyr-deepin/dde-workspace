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

try
    settings = DCore.DBus.session_object(
        "com.deepin.dde.daemon.Launcher",
        "/com/deepin/dde/daemon/Launcher",
        "com.deepin.dde.daemon.launcher.Setting"
    )
catch e
    console.error(e)
    DCore.Launcher.quit()

launcherSetting = new Setting(settings)

init_all_applications = ->
    # get all applications and sort them by name
    _all_items = daemon.GetAllItemInfos_sync()
    autostartList = startManager.AutostartList_sync()

    for core in _all_items
        createItem(core, autostartList)

init_all_applications()
console.log "load all applications done"

switcher = new Switcher(launcherSetting)
console.log "load switcher done"

searchResult = new SearchResult()
searchBar = new SearchBar()
daemon.connect("SearchDone", searchResult.update)
console.log "create search bar done"

categoryInfos = daemon.GetAllCategoryInfos_sync()
console.log "get category infos done"

categoryBar = new CategoryBar(categoryInfos, launcherSetting.getCategoryDisplayMode(), launcherSetting.getSortMethod())
console.log "load category bar done"

categoryList = makeCategoryList(launcherSetting.getSortMethod())
console.log "load category list done"

launcherSetting.listenSortMethodChanged((newMethod)->
    categoryList.reset()
    categoryBar.sortMethod = newMethod
    switcher.isShowCategory = newMethod == SortMethod.Method.ByCategory
    categoryList = makeCategoryList(newMethod)
    selector.container(categoryList)
    if switcher.isShowCategory
        categoryBar.show()
        categoryBar.focusCategory(categoryList.firstCategory()?.id)
    else
        categoryBar.hide()
    categoryList.getBox().offsetTop
)
launcherSetting.listenCategoryDisplayModeChanged((newMode)=>
    categoryBar.changeDisplayMode(newMode)
)

bind_events()
console.log "bind event done"

selector = new Selector()
selector.container(categoryList)
console.log "create selector done"

DCore.Launcher.webview_ok()
console.log "webview ok"

DCore.Launcher.test()
