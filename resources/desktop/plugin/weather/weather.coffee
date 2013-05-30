#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 bluth
#
#encoding: utf-8
#Author:      bluth <\yuanchenglu@linuxdeepin.com>
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

class Weather extends Widget
    constructor: ->
        super(null)
        @weather_style_build()
        @more_weather_build()

        cityid = localStorage.getItem("cityid_storage")
        echo "cityid:" + cityid 
        if !cityid
            Clientcityid = new ClientCityId()
            Clientcityid.Get_client_cityip(@weathergui_update.bind(@))
        else @weathergui_update()

    do_buildmenu:->
        []
    weather_style_build: ->
        @img_url_first = "#{plugin.path}/img/"
        img_now_url_init = @img_url_first + "48/T" + "0\u6674" + ".png"
        temp_now_init = "0"

        left_div = create_element("div", "left_div", @element)
        @weather_now_pic = create_img("weather_now_pic", img_now_url_init, left_div)

        right_div = create_element("div","right_div",@element)
        temperature_now = create_element("div", "temperature_now", right_div)
        @temperature_now_minus = create_element("div", "temperature_now_minus", temperature_now)
        @temperature_now_minus.textContent = "-"
        @temperature_now_number = create_element("div", "temperature_now_number", temperature_now)
        @temperature_now_number.textContent = temp_now_init

        city_and_date = create_element("div","city_and_date",right_div)
        city = create_element("div","city",city_and_date)
        @city_now = create_element("div", "city_now", city)
        @city_now.textContent = _("choose city")
        @more_city_img = create_img("more_city_img", @img_url_first + "ar.png", city)
        @date = create_element("div", "date", city_and_date)
        @date.textContent =  _("loading") + ".........."

        @more_city_menu = new CityMoreMenu(0,84,65535)
        @element.appendChild(@more_city_menu.element)

        @global_desktop = create_element("div","global_desktop",@element)
        @global_desktop.style.height = window.screen.height
        @global_desktop.style.width = window.screen.width
        @global_desktop.style.zIndex = @more_city_menu.zIndex_check() - 1

        city.addEventListener("click", =>
            @more_weather_menu.style.display = "none"

            if @more_city_menu.display_check() == "none"
               @global_desktop.style.display = "block"
            else @global_desktop.style.display = "none"

            bottom_distance =  window.screen.availHeight - @element.getBoundingClientRect().bottom
            @more_city_menu.show_hide_position(bottom_distance)

            @more_city_menu.more_city_build()
            @more_city_menu.change_chooseprov(@weathergui_update.bind(@))
            )
        @date.addEventListener("click", =>
            @more_city_menu.display_none()

            if @more_weather_menu.style.display == "none"
                @global_desktop.style.display = "block"
                bottom_distance =  window.screen.availHeight - @element.getBoundingClientRect().bottom
                if bottom_distance < 200
                    @more_weather_menu.style.top = -195
                else @more_weather_menu.style.top = 84
                @more_weather_menu.style.display = "block"
            else
                @global_desktop.style.display = "none"
                @more_weather_menu.style.display = "none"
            )
        @global_desktop.addEventListener("click",=>
            # echo "display none all menu"
            @more_weather_menu.style.display = "none"
            @more_city_menu.display_none()
            @global_desktop.style.display = "none"
            )

    more_weather_build: ->
        
        img_now_url_init = @img_url_first + "48/T" + "0\u6674" + ".png"
        img_more_url_init = @img_url_first + "24/T" + "0\u6674" + ".png"
        week_init = _("Sun")
        temp_init = "00℃~00℃"

        @more_weather_menu = create_element("div", "more_weather_menu", @element)
        @more_weather_menu.style.display = "none"

        @first_day_weather_data = create_element("div", "first_day_weather_data", @more_weather_menu)
        @week1 = create_element("a", "week1", @first_day_weather_data)
        @week1.textContent = week_init
        @pic1 = create_img("pic1", img_more_url_init, @first_day_weather_data)
        @temperature1 = create_element("a", "temperature1", @first_day_weather_data)
        @temperature1.textContent = temp_init

        @second_day_weather_data = create_element("div", "second_day_weather_data", @more_weather_menu)
        @week2 = create_element("a", "week2", @second_day_weather_data)
        @week2.textContent = week_init
        @pic2 = create_img("pic2", img_more_url_init, @second_day_weather_data)
        @temperature2 = create_element("a", "temperature2", @second_day_weather_data)
        @temperature2.textContent = temp_init

        @third_day_weather_data = create_element("div", "third_day_weather_data", @more_weather_menu)
        @week3 = create_element("a", "week3", @third_day_weather_data)
        @week3.textContent = week_init
        @pic3 = create_img("pic3", img_more_url_init, @third_day_weather_data)
        @temperature3 = create_element("a", "temperature3", @third_day_weather_data)
        @temperature3.textContent = temp_init

        @fourth_day_weather_data = create_element("div", "fourth_day_weather_data", @more_weather_menu)
        @week4 = create_element("a", "week4", @fourth_day_weather_data)
        @week4.textContent = week_init
        @pic4 = create_img("pic4", img_more_url_init, @fourth_day_weather_data)
        @temperature4 = create_element("a", "temperature4", @fourth_day_weather_data)
        @temperature4.textContent = temp_init

        @fifth_day_weather_data = create_element("div", "fifth_day_weather_data", @more_weather_menu)
        @week5 = create_element("a", "week5", @fifth_day_weather_data)
        @week5.textContent = week_init
        @pic5 = create_img("pic5", img_more_url_init, @fifth_day_weather_data)
        @temperature5 = create_element("a", "temperature5", @fifth_day_weather_data)
        @temperature5.textContent = temp_init

        @sixth_day_weather_data = create_element("div", "sixth_day_weather_data", @more_weather_menu)
        @week6 = create_element("a", "week6", @sixth_day_weather_data)
        @week6.textContent = week_init
        @pic6 = create_img("pic6", img_more_url_init, @sixth_day_weather_data)
        @temperature6 = create_element("a", "temperature6", @sixth_day_weather_data)
        @temperature6.textContent = temp_init



    weathergui_update: ->
            cityid = localStorage.getItem("cityid_storage")
            clearInterval(@auto_weathergui_refresh)
            @auto_weathergui_refresh = setInterval(@weathergui_refresh(cityid),600000)# ten minites update once 1800000   60000--60s

    weathergui_refresh: (cityid)->
        callback_now = ->
            weather_data_now = localStorage.getObject("weatherdata_now_storage")
            @update_weathernow(weather_data_now)
        callback_more = ->
            weather_data_more = localStorage.getObject("weatherdata_more_storage")
            @update_weathermore(weather_data_more)
        if cityid
            @weatherdata = new WeatherData(cityid)
            @weatherdata.Get_weatherdata_now(callback_now.bind(@))
            @weatherdata.Get_weatherdata_more(callback_more.bind(@))
        else
            echo "cityid isnt ready"

    update_weathernow: (weather_data_now)->
        # echo "weather_data_now:" + weather_data_now
        temp_now = weather_data_now.weatherinfo.temp
        @time_update = weather_data_now.weatherinfo.time
        echo "temp_now:" + temp_now
        # show the   name in chinese not in english
        @city_now.textContent = weather_data_now.weatherinfo.city

        if temp_now == "\u6682\u65e0\u5b9e\u51b5"
            @temperature_now_number.textContent = _("None")
        else
            if temp_now < -10
                @temperature_now_minus.style.opacity = 0.8
                @temperature_now_number.textContent = -temp_now
            else
                @temperature_now_minus.style.opacity = 0
                @temperature_now_number.textContent = temp_now

    update_weathermore: (weather_data_more)->
        week_n = @weatherdata.week_n
        week_show = [_("Sun"), _("Mon"), _("Tue"), _("Wed"), _("Thu"), _("Fri"), _("Sat")]
        str_data = weather_data_more.weatherinfo.date_y
        @date.textContent = str_data.substring(0,str_data.indexOf("\u5e74")) + "." + str_data.substring(str_data.indexOf("\u5e74")+1,str_data.indexOf("\u6708"))+ "." + str_data.substring(str_data.indexOf("\u6708") + 1,str_data.indexOf("\u65e5")) + " " + week_show[week_n%7]
        @weather_now_pic.src = @img_url_first + "48/T" + weather_data_more.weatherinfo.img_single + weather_data_more.weatherinfo.img_title_single + ".png"

        @week1.textContent = week_show[week_n%7]
        @pic1.src = @weather_more_pic_src(1)
        @temperature1.textContent = weather_data_more.weatherinfo.temp1
        @week2.textContent = week_show[(week_n+1)%7]
        @pic2.src = @weather_more_pic_src(2)
        @temperature2.textContent = weather_data_more.weatherinfo.temp2
        @week3.textContent = week_show[(week_n+2)%7]
        @pic3.src = @weather_more_pic_src(3)
        @temperature3.textContent = weather_data_more.weatherinfo.temp3
        @week4.textContent = week_show[(week_n+3)%7]
        @pic4.src = @weather_more_pic_src(4)
        @temperature4.textContent = weather_data_more.weatherinfo.temp4
        @week5.textContent = week_show[(week_n+4)%7]
        @pic5.src = @weather_more_pic_src(5)
        @temperature5.textContent = weather_data_more.weatherinfo.temp5
        @week6.textContent = week_show[(week_n+5)%7]
        @pic6.src = @weather_more_pic_src(6)
        @temperature6.textContent = weather_data_more.weatherinfo.temp6

    weather_more_pic_src:(i) ->
        i = i*2 - 1
        src = null
        time = new Date()
        hours_now = time.getHours()
        img_front = @weatherdata.img_front
        img_behind = @weatherdata.img_behind
        if img_front[i+1] == "99"
            img_front[i+1] = img_front[i]
        if hours_now < 12
            src = @img_url_first + "24/T" + img_front[i] + img_behind[i] + ".png"
        else src = @img_url_first + "24/T" + img_front[i+1] + img_behind[i+1] + ".png"
        return src

plugin = window.plugin_manager.get_plugin("weather")
plugin.inject_css("weather")
plugin.inject_css("citymoremenu")

plugin.wrap_element(new Weather(plugin.id).element)
plugin.set_pos(
    x: 9
    y: 0
    width: 3
    height: 1
)
