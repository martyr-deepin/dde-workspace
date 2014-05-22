#Copyright (c) 2011 ~  Deepin, Inc.
#              2013 ~  Lee Liqiang
#
#Author:      Lee Liqiang <liliqiang@linuxdeepin.com>
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

SWITCHER_WIDTH = 64
ITEM_WIDTH = 160
ITEM_HEIGHT = 160

CONTAINER_BOTTOM_MARGIN = 70
SEARCH_BAR_HEIGHT = 50
GRID_PADDING = 110
GRID_EXTRA_LEFT_PADDING = 45
CATEGORY_LIST_ITEM_MARGIN = 20
CATEGORY_BAR_ITEM_MARGIN = 10

INVALID_IMG = "invalid-dock_app"

SCROLL_STEP_LEN = ITEM_HEIGHT

CATEGORY_ID =
    ALL: -1
    OTHER: -2
    FAVOR: -3
    INTERNET: 0
    MULTIMEDIA: 1
    GAMES: 2
    GRAPHICS: 3
    PRODUCTIVITY: 4
    INDUSTRY: 5
    EDUCATION: 6
    DEVELOPMENT: 7
    SYSTEM: 8
    UTILITIES: 9

NUM_SHOWN_ONCE = 10

ITEM_IMG_SIZE = 48

GRID_MARGIN_BOTTOM = 30

KEYCODE.BACKSPACE = 8
KEYCODE.TAB = 9
KEYCODE.P = 80
KEYCODE.N = 78
KEYCODE.B = 66
KEYCODE.F = 70

HIDDEN_ICONS_MESSAGE =
    true: _("_Hide hidden icons")
    false: _("_Display hidden icons")

ITEM_HIDDEN_ICON_MESSAGE =
    'display': _("_Hide this icon")
    'hidden': _("_Display this icon")

AUTOSTART_MESSAGE =
    false: _("_Add to autostart")
    true: _("_Remove from autostart")

AUTOSTART_ICON =
    NAME: "emblem-autostart"
    SIZE: 16

FAVOR_MESSAGE =
    false: _("Add to _favorites")
    true: _("Remove from _favorites")

MASK_TOP_BOTTOM = "-webkit-linear-gradient(top, rgba(0,0,0,0), rgba(0,0,0,1) 5%, rgba(0,0,0,1) 90%, rgba(0,0,0,0.3), rgba(0,0,0,0))"
