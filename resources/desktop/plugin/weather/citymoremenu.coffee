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
    constructor: (x,y,zIndex,y2)->
        super(null)
        @y = y
        @y2 = y2
        @element.style.left = x 
        @element.style.top = @y
        @element.style.display = "none"
        @element.style.zIndex = zIndex
        # @lable = create_element("lable","lable",@element)


    show_hide_position:(bottom_distance)->
        bottom_distance_mini = @selectsize * 12 + 40
        echo "bottom_distance_mini:" + bottom_distance_mini
        # bottom_distance_mini = 200
        if @element.style.display == "none"
            if bottom_distance < bottom_distance_mini
                @element.style.top = @y2
            else @element.style.top = @y
            @element.style.display = "block"
        else
            @element.style.display = "none"

    display_none:->
        @element.style.display = "none"

    display_check:->
        return @element.style.display

    zIndex_check:->
        return @element.style.zIndex

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
        @prov = create_element("div","prov",@element)
        @city = create_element("div","city",@element)
        @dist = create_element("div","dist",@element)
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
        # @chooseprov.onblur = =>
        #     echo "@chooseprov onblur"
        #     @setOptionSelectedColor(@chooseprov,@provIndex,"#F0F")
            
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
            # echo "cityIndex:" + cityIndex
            if cityIndex == -1
                @choosecity.options.remove(cityIndex)
            else
                cityvalue = @choosecity.options[cityIndex].value
                # echo "cityvalue:" + cityvalue
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
                    cityid_choose = data[distvalue].data
                    localStorage.setItem("cityid_storage",cityid_choose)
                    callback()

    clearOptions:(colls,first=0)->
        i = first
        # colls.remove(i++) while i < colls.length 
        colls.options.length = i

    remove_element:(obj)->
        obj.parentNode.removeChild(obj) if obj

    setMaxSize:(obj,val=@selectsize)->
        length = obj.options.length
        obj.size = if length < val then length else val

    create_option:(obj,data)->
        for i of data
            # obj.add(new Div(data[i].name, i))
            obj.options.add(new Option(data[i].name, i))
    setOptionSelectedColor:(obj,index,color)->
        index = obj.selectedIndex if !index
        obj.options[index].style.background = color