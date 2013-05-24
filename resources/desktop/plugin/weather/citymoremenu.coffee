#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 bluth
#
#encoding: utf-8
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
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

class CityMoreMenu
    # @display_city_menu_id = null#setTimeOut hide the citymoremenu
    @cityid_choose = null

    constructor: (clss, parent,x,y,position=absolute)->
        @more_city_menu = create_element("div", "more_city_menu", parent)
        @more_city_menu.setAttribute("class", clss) if  clss
        if parent
            parent.appendChild(@more_city_menu)
        @more_city_menu.style.display = "none"
        @more_city_menu.style.position = position if position
        @more_city_menu.style.left = x if x
        @more_city_menu.style.top = y if y

        @more_city_build()

        return @more_city_menu

    more_city_build: ->
        @str_provinit = "--" + _("province") + "--"
        @str_cityinit = "--" + _("city") + "--" 
        @str_distinit = "--" + _("county") + "--"
        @chooseprov = create_element("select", "chooseprov", @more_city_menu)
        @choosecity = create_element("select", "choosecity", @more_city_menu)
        @choosedist = create_element("select", "choosedist", @more_city_menu)

        @chooseprov.options.length = 0 
        provinit = create_element("option","provinit",@chooseprov)
        provinit.innerText = @str_provinit
        provinit.selected = "true"
        i = 0
        while i < cities.length
            @chooseprov.options.add(new Option(cities[i].name, cities[i++].id))
        length = @chooseprov.options.length
        @chooseprov.size = (if (length < 13) then length else 13)
        @choosecity.size = 1
        @choosecity.options.length = 0 
        cityinit = create_element("option", "cityinit", @choosecity)
        cityinit.innerText = @str_cityinit
        cityinit.selected = "true"
        @choosedist.size = 1
        @choosedist.options.length = 0
        distinit = create_element("option", "distinit", @choosedist)
        distinit.innerText = @str_distinit
        distinit.selected = "true"
        

        @chooseprov.addEventListener("change", =>
            provIndex = @chooseprov.selectedIndex
            if provIndex is -1
                @chooseprov.options.remove(provIndex)
            else
                provvalue = @chooseprov.options[provIndex].value 
                if provvalue isnt @str_provinit
                    data = @read_data_from_json(provvalue)
                )

    read_data_from_json: (id) ->
        xhr = new XMLHttpRequest()
        url = "city/" + id + ".json"
        xhr.open("GET", url, true)
        xhr.send(null)
        xhr.onreadystatechange = =>
            if (xhr.readyState == 4)
                if xhr.responseText isnt "" && xhr.responseText isnt null
                    data = JSON.parse(xhr.responseText);
                    @cityadd(data[id].data)

    cityadd: (data) ->
        @choosecity.options.length = 1
        for i of data
            @choosecity.options.add(new Option(data[i].name, i))
        length = @choosecity.options.length
        @choosecity.size = (if (length < 13) then length else 13)   
        @choosecity.onchange = =>
            cityIndex = @choosecity.selectedIndex
            if cityIndex is -1
                @choosecity.options.remove(cityIndex)
            else
                cityvalue = @choosecity.options[cityIndex].value
                if cityvalue isnt @str_cityinit
                    @distadd(data[cityvalue].data)
    
    distadd: (data) ->
        @choosedist.options.length = 1
        for i of data
            @choosedist.options.add(new Option(data[i].name, i))
        length = @choosedist.options.length
        @choosedist.size = (if (length < 13) then length else 13)
        @choosedist.onchange = =>
            clearInterval(@auto_update_cityid_choose)
            @more_city_menu.style.display = "none"
            distIndex = @choosedist.selectedIndex
            if distIndex is -1
                @choosedist.options.remove(distIndex)
            else
                distvalue = @choosedist.options[distIndex].value
                if distvalue isnt @str_distinit
                    cityid_choose = data[distvalue].data
                    localStorage.setItem("cityid_storage",cityid_choose)
                    @cityid_choose = localStorage.getItem("cityid_storage")
                    weather = new Weather()
                    echo "@cityid_choose:" + @cityid_choose
    
