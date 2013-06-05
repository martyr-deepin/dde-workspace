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
    BOTTOM_DISTANCE_MINI = 200
    times_dist_choose = 0
    common_dists_init = [
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

    constructor: (zIndex,callback)->
        super(null)
        @element.style.display = "none"
        @element.style.zIndex = zIndex

    display_none:->
        @element.style.display = "none"
    display_block:->
        @element.style.display = "block"

    display_check:->
        return @element.style.display

    zIndex_check:->
        return @element.style.zIndex
    set_menu_position:(obj,bottom_distance,x1,y1,x2,y2,show = "block")->
        # echo obj
        # echo x1 + "," + y1 + ";" + x2 + "," + y2 + ";" + show
        if bottom_distance > BOTTOM_DISTANCE_MINI
            obj.style.left = x1
            obj.style.top = y1
        else 
            obj.style.left = x2
            obj.style.top = y2
        obj.style.display = show if obj

    common_city_build:(bottom_distance,x1,y1,x2,y2,callback)->
        @element.style.display = "block"
        @lable_choose.style.display = "none" if @lable_choose
        @remove_element(@common_menu) if @common_menu

        @common_menu = create_element("div","common_menu",@element)
        @common_menu.style.display = "none"

        common_dists = localStorage.getObject("common_dists_storage")
        if common_dists
            common_city = []
            i = 0
            while i < common_dists.length
                if common_dists[i].name && common_dists[i].id
                    common_city = create_element("div","common_city",@common_menu)

                    common_city_text = create_element("div","common_city_text",common_city)
                    common_city_text.innerText = common_dists[i].name 
                    common_city_text.value = common_dists[i].id

                    minus = create_element("div","minus",common_city)
                    minus.innerText = "-"

                    that = @
                    common_city_text.addEventListener("click",->
                        that.element.style.display = "none"
                        localStorage.setItem("cityid_storage",this.value)
                        that = null
                        callback()
                        )
                    minus.addEventListener("click",->
                        # that.remove_element(common_city) if common_city
                        )
                i++

        @add_common_city = create_element("div","add_common_city",@common_menu)
        plus =  create_element("div","plus",@add_common_city)
        plus.innerText = "+"

        @set_menu_position(@common_menu,bottom_distance,x1,y1,x2,y2,"block")

    more_city_build:(selectsize,bottom_distance,x1,y1,x2,y2,callback)->
        @add_common_city.addEventListener("click",=>
            @common_menu.style.display = "none"
            @more_city_create(selectsize)
            @set_menu_position(@lable_choose,bottom_distance,x1,y1,x2,y2,"block")
            @change_chooseprov(callback)
            )

    more_city_create: (selectsize)->
        @selectsize = selectsize


        @remove_element(@lable_choose) if @lable_choose
        @remove_element(choose) if choose
        @remove_element(prov) if prov
        @remove_element(city) if city
        @remove_element(dist) if dist
        @remove_element(@chooseprov) if @chooseprov
        @remove_element(@choosecity) if @choosecity
        @remove_element(@choosedist) if @choosedist

        @lable_choose = create_element("div","lable_choose",@element)
        @lable_choose.style.display = "none"

        choose = create_element("div","choose",@lable_choose)

        @str_provinit = "-" + _("province") + "-"
        @str_cityinit = "-" + _("city") + "-" 
        @str_distinit = "-" + _("county") + "-"
        prov = create_element("div","prov",choose)
        city = create_element("div","city",choose)
        dist = create_element("div","dist",choose)
        @chooseprov = create_element("select", "chooseprov", prov)
        @choosecity = create_element("select", "choosecity", city)
        @choosedist = create_element("select", "choosedist", dist)

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

                    times = localStorage.getObject("times_dist_choose_storage")
                    echo times
                    times_dist_choose = if !times then 0 else times
                    echo times_dist_choose

                    common = localStorage.getObject("common_dists_storage")
                    echo common
                    common_dists = if !common then common_dists_init else common
                    echo common_dists

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