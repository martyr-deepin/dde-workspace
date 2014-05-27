#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 snyh
#
#Author:      Cole <phcourage@gmail.com>
#             bluth <yuanchenglu001@gmail.com>
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

# const strings and functions for desktop internal DND operation
_DND_DATA_TYPE_NAME_ = "text/operate-type"
_DND_DESKTOP_MARK_ = "desktop_internal"
_DND_RICHDIR_MARK_ = "richdir_internal"

RICHDIR_FLAG = false

_SET_DND_INTERNAL_FLAG_ = (evt) ->
    evt.dataTransfer.setData(_DND_DATA_TYPE_NAME_, _DND_DESKTOP_MARK_)

_IS_DND_INTERLNAL_ = (evt) ->
    evt.dataTransfer.getData(_DND_DATA_TYPE_NAME_) == _DND_DESKTOP_MARK_


_SET_DND_RICHDIR_FLAG_ = (evt) ->
    evt.dataTransfer.setData(_DND_DATA_TYPE_NAME_, _DND_RICHDIR_MARK_)

_IS_DND_RICHDIR_ = (evt) ->
    evt.dataTransfer.getData(_DND_DATA_TYPE_NAME_) == _DND_RICHDIR_MARK_

# item real size on grid
_ITEM_WIDTH_ = 80 + 6 * 2
_ITEM_HEIGHT_ = 84 + 4 * 2

# separate the grid to 4*4=16 parts
_PART_ = 4

# one grid size init
_GRID_WIDTH_INIT_ = Math.floor(_ITEM_WIDTH_/_PART_)
_GRID_HEIGHT_INIT_ = Math.floor(_ITEM_HEIGHT_/_PART_)

# delay interval time before renaming item
_RENAME_TIME_DELAY_ = 600


# id string for "computer" item
_ITEM_ID_COMPUTER_  = "Computer_Virtual_Dir"
# id string for "home" item
_ITEM_ID_USER_HOME_ = "Home_Virtual_Dir"
# id string for "trash bin" item
_ITEM_ID_TRASH_BIN_ = "Trash_Virtual_Dir"
# id string for "Deepin Software Center" item
_ITEM_ID_DSC_ = "DSC_Virtual_Button"

# id string for "computer" icon
_ICON_ID_COMPUTER_  = "computer"
# id string for "home" icon
_ICON_ID_USER_HOME_ = "deepin-user-home"
# id string for "trash bin" normal icon
_ICON_ID_TRASH_BIN_FULL_ = "user-trash-full"
# id string for "trash bin" empty icon
_ICON_ID_TRASH_BIN_ = "user-trash"
# id string for "Deepin Software Center" icon
_ICON_ID_DSC_ = "deepin-software-center"

# desktop icon size category
D_ICON_SIZE_SMALL  = 16
D_ICON_SIZE_NORMAL = 48
D_ICON_SIZE_BIG    = 96
APP_DEFAULT_ICON = "application-default-icon"
FILE_DEFAULT_ICON = "unknown"

# icon name for file attributes
_FAI_READ_ONLY_  = "emblem-readonly"
_FAT_SYM_LINK_   = "emblem-symbolic-link"
_FAT_UNREADABLE_ = "emblem-unreadable"

# store the entry for desktop
desktop_path = DCore.Desktop.get_desktop_path()
g_desktop_entry = DCore.DEntry.create_by_path(desktop_path)
desktop_uri = DCore.DEntry.get_uri(g_desktop_entry)

# const names to get configs
_CFG_SHOW_COMPUTER_ICON_ = "show-computer-icon"
_CFG_SHOW_HOME_ICON_ = "show-home-icon"
_CFG_SHOW_TRASH_BIN_ICON_ = "show-trash-icon"
_CFG_SHOW_DSC_ICON_ = "show-dsc-icon"

# wrapper func to get configs
_GET_CFG_BOOL_ = (val) ->
    DCore.Desktop.get_config_boolean(val)

DSS = "com.deepin.dde.ControlCenter"
