#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
#Maintainer:  LongWei <yilang2007lw@gmail.com>
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

format_two_bit = (s) ->
        if s < 10
                return "0#{s}"
        else
                return s

get_time_str = ->
        hours = format_two_bit new Date().getHours()
        min = format_two_bit new Date().getMinutes()
        return "#{hours}:#{min}"

get_date_str = ->
        month_list = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
        day_list = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

        day = day_list[new Date().getDay()]
        mon = month_list[new Date().getMonth()]
        date = new Date().getDate()
        year = new Date().getFullYear()

        return "#{day}, #{mon} #{date}, #{year}"

get_power_info = ->
        echo "get power info"
        power_info = {}

        if DCore.Greeter.get_can_suspend()
                power_info["suspend"] = suspend
        if DCore.Greeter.get_can_hibernate()
                power_info["hibernate"] = hibernate
        if DCore.Greeter.get_can_restart()
                power_info["restart"] = restart
        if DCore.Greeter.get_can_shutdown()
                power_info["shutdown"] = shutdown

        return power_info                                        

suspend = ->
        echo "suspend"
        # return DCore.Greeter.suspend()

hibernate = ->
        echo "hibernate"
        # return DCore.Greeter.hibernate()

restart = ->
        echo "restart"
        # return DCore.Greeter.restart()

shutdown = ->
        echo "shutdown"
        # return DCore.Greeter.shutdown()

get_de_info = ->
        echo "get desktop environment info"
        de_info = {"gnome":"gnome", "deepin":"deepin"}

        return de_info

class Time extends Widget
        constructor: (@id)->
                super
                document.body.appendChild(@element)
                @time_div = create_element("div", "Time01", @element)
                @date_div = create_element("div", "Time02", @element)
                @update()
                setInterval(=>
                        @update()
                , 1000)

        update: ->
                @time_div.innerText = get_time_str()
                @date_div.innerText = get_date_str()
                return true
                                                                
time_container = new Time("time")

class Ver extends Widget
        constructor: (@id)->
                super
                document.body.appendChild(@element)

ver_container = new Ver("deepin")

class DEText extends Widget
        constructor: (@id)->
                super
                document.body.appendChild(@element)
                @element.innerText = """
                        Choose Desktop Environment
                """
detext_container = new DEText("detext")

class MenuContainer extends Widget
        constructor: (@id, @items) ->
                super
                document.body.appendChild(@element)
                @control_div = create_element("div", "MenuControl", @element)
                @switch_div = create_element("div", "MenuSwitch", @control_div)
                @menu_div = create_element("div", "Menu", @control_div)

                @create_menu_items()

        create_menu_items: () ->
                @menu_ul = create_element("ul", " ", @menu_div)
                for key, value of @items
                        menu_li = create_element("li", " ", @menu_ul)
                        menu_li.innerText = key
                        menu_li.addEventListener("click", @on_menu_click)

        on_menu_click: (event) =>
                key = event.srcElement.innerText                
                @items[key]()

de_container = new MenuContainer("desktop",  get_de_info())

power_container = new MenuContainer("power", get_power_info())
                        