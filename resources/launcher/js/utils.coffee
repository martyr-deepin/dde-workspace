#Copyright (c) 2011 ~  Deepin, Inc.
#              2013 ~ Lee Liqiang
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


get_name_by_id = (id) ->
    if Widget.look_up(id)?
        DCore.DEntry.get_name(Widget.look_up(id).core)
    else
        ""


compare_string = (s1, s2) ->
    return 1 if s1 > s2
    return 0 if s1 == s2
    return -1


sort_by_name = (items)->
    items.sort((lhs, rhs)->
        lhs_name = get_name_by_id(lhs)
        rhs_name = get_name_by_id(rhs)
        compare_string(lhs_name, rhs_name)
    )


sort_by_rate = do ->
    rates = null
    items_name_map = {}

    (items, update)->
        if update
            rates = DCore.Launcher.get_app_rate()

            items_name_map = {}
            for id in category_infos[ALL_APPLICATION_CATEGORY_ID]
                if not items_name_map[id]?
                    items_name_map[id] =
                        DCore.DEntry.get_appid(Widget.look_up(id).core)

        items.sort((lhs, rhs)->
            lhs_appid = items_name_map[lhs]
            lhs_rate = rates[lhs_appid] if lhs_appid?

            rhs_appid = items_name_map[rhs]
            rhs_rate = rates[rhs_appid] if rhs_appid?

            if lhs_rate? and rhs_rate?
                rates_delta = rhs_rate - lhs_rate
                if rates_delta == 0
                    return compare_string(get_name_by_id(lhs), get_name_by_id(rhs))
                else
                    return rates_delta
            else if lhs_rate? and not rhs_rate?
                return -1
            else if not lhs_rate? and rhs_rates?
                return 1
            else
                return compare_string(get_name_by_id(lhs), get_name_by_id(rhs))
        )


SORT_METHOD =
    name: sort_by_name
    rate: sort_by_rate

exit_launcher = ->
    DCore.Launcher.exit_gui()
