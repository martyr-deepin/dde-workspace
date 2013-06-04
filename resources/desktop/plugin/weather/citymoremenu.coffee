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

class CityMoreMenu extends Widget
    times_dist_choose = 0
    common_dists = [
      {
        "name":"",
        "id":""
      },{
        "name":"",
        "id":""
      },{
        "name":"",
        "id":""
      },{
        "name":"",
        "id":""
      },{
        "name":"",
        "id":""
      }
    ]

    constructor: (x,y,zIndex,y2)->
        super(null)
        @x = x
        @y = y
        @y2 = y2
        @element.style.left = @x 
        @element.style.top = @y
        @element.style.display = "none"
        @element.style.zIndex = zIndex
        @lable_choose = create_element("lable","lable_choose",@element)

    display_none:->
        @element.style.display = "none"
    display_block:->
        @element.style.display = "block"

    display_check:->
        return @element.style.display

    zIndex_check:->
        return @element.style.zIndex

    show_hide_position:(bottom_distance)->
        bottom_distance_mini = @selectsize * 12 + 40
        @lable_choose.style.display = "none" if @lable_choose
        if @element.style.display == "none"
            if bottom_distance < bottom_distance_mini
                @element.style.top = @y2
            else @element.style.top = @y
            @common_menu.style.display = "block" if @common_menu
            @element.style.display = "block"

    common_city_build:(x=135,y=-25)->
        @remove_element(@common_menu) if @common_menu
        @common_menu = create_element("div","common_menu",@element)
        @common_menu.style.left = x 
        @common_menu.style.top = y
        @common_city = []

        common_dists = localStorage.getObject("common_dists_storage")
        # echo common_dists
        i = 0
        while i < common_dists.length
            if common_dists[i].name && common_dists[i].id
                @common_city[i] = create_element("div","common_city",@common_menu)
                @common_city[i].innerText = common_dists[i].name 
                @common_city[i].value = common_dists[i].id
            i++

        @add_common_city = create_element("div","add_common_city",@common_menu)
        @add_common_city.innerText = _("choose city")

        for div , i in @common_city
            # echo div
            name = div.innerText
            value = div.value
            @common_city[i].addEventListener("click",=>
                @element.style.display = "none"
                echo name
                echo value
                localStorage.setItem("cityid_storage",value)
                callback()
                )

    addcity:(selectsize,callback)->
        @add_common_city.addEventListener("click",=>
            @common_menu.style.display = "none"
            @lable_choose.style.display = "block"
            @more_city_build(selectsize)
            @change_chooseprov(callback)
            )

    more_city_build: (selectsize)->
        @selectsize = selectsize

        @remove_element(@prov) if @prov
        @remove_element(@city) if @city
        @remove_element(@dist) if @dist
        @remove_element(@chooseprov) if @chooseprov
        @remove_element(@choosecity) if @choosecity
        @remove_element(@choosedist) if @choosedist

        @str_provinit = "-" + _("province") + "-"
        @str_cityinit = "-" + _("city") + "-" 
        @str_distinit = "-" + _("county") + "-"
        @prov = create_element("div","prov",@lable_choose)
        @city = create_element("div","city",@lable_choose)
        @dist = create_element("div","dist",@lable_choose)
        @chooseprov = create_element("select", "chooseprov", @prov)
        @choosecity = create_element("select", "choosecity", @city)
        @choosedist = create_element("select", "choosedist", @dist)

        @clearOptions(@chooseprov,0)
        provinit = create_element("option","provinit",@chooseprov)
        provinit.innerText = @str_provinit
        provinit.selected = "false"
        i = 0
        @chooseprov.options.add(new Option(cities[i].name, cities[i++].id)) while i < cities.length
        @setMaxSize(@chooseprov)

        @clearOptions(@choosecity,0)
        cityinit = create_element("option", "cityinit", @choosecity)
        cityinit.innerText = @str_cityinit
        cityinit.style.textAlign = "center" 
        cityinit.selected = "false"
        
        @clearOptions(@choosedist,0)
        distinit = create_element("option", "distinit", @choosedist)
        distinit.innerText = @str_distinit
        distinit.selected = "false"

    change_chooseprov: (callback)->
        @chooseprov.addEventListener("change", =>
            @provIndex = @chooseprov.selectedIndex

            if @provIndex == -1
                @chooseprov.options.remove(@provIndex)
            else
                provvalue = @chooseprov.options[@provIndex].value 
                if provvalue != @str_provinit
                    data = @read_data_from_json(provvalue,callback)
            )

    read_data_from_json: (id,callback) -> 
        url = "#{plugin.path}/city/" + id + ".json"
        ajax(url,(xhr)=>
            if xhr.responseText
                data = JSON.parse(xhr.responseText)
                @cityadd(data[id].data,callback)
        ,false)

    cityadd: (data,callback) ->
        @clearOptions(@choosecity,1)#1
        @create_option(@choosecity,data)
        @setMaxSize(@choosecity)
        @choosecity.onchange = =>

            cityIndex = @choosecity.selectedIndex
            if cityIndex == -1
                @choosecity.options.remove(cityIndex)
            else
                cityvalue = @choosecity.options[cityIndex].value
                if cityvalue != @str_cityinit
                    @distadd(data[cityvalue].data,callback)
    
    distadd: (data,callback) ->
        @clearOptions(@choosedist,1)#1
        @create_option(@choosedist,data)
        @setMaxSize(@choosedist)
        @choosedist.onchange = =>
            clearInterval(@auto_update_cityid_choose)
            @element.style.display = "none"
            distIndex = @choosedist.selectedIndex
            if distIndex == -1
                @choosedist.options.remove(distIndex)
            else
                distvalue = @choosedist.options[distIndex].value
                if distvalue != @str_distinit

                    times_dist_choose = localStorage.getObject("times_dist_choose_storage") if times_dist_choose
                    common_dists = localStorage.getObject("common_dists_storage") if common_dists
                    common_dists[times_dist_choose].name = data[distvalue].name
                    common_dists[times_dist_choose].id = data[distvalue].data
                    localStorage.setObject("common_dists_storage",common_dists)
                    times_dist_choose++
                    if times_dist_choose > 4 then times_dist_choose = 0 
                    localStorage.setItem("times_dist_choose_storage",times_dist_choose)

                    echo data[distvalue].name
                    echo data[distvalue].data
                    localStorage.setItem("cityid_storage",data[distvalue].data)
                    callback()

    clearOptions:(colls,first=0)->
        i = first
        # colls.remove(i++) while i < colls.length 
        colls.options.length = i

    remove_element:(obj)->
        obj.parentNode.removeChild(obj) if obj

    setMaxSize:(obj,val=@selectsize)->
        # length = obj.options.length
        # obj.size = if length < val then length else val
        obj.size = val

    create_option:(obj,data)->
        for i of data
            obj.options.add(new Option(data[i].name, i))
    setOptionSelectedColor:(obj,index,color)->
        index = obj.selectedIndex if !index
        obj.options[index].style.background = color