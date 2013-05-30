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

class WeatherData

    constructor: (cityid)->
        @url_nowweather_str = "http://www.weather.com.cn/data/sk/"+ cityid + ".html" 
        @url_moreweather_str = "http://m.weather.com.cn/data/" + cityid + ".html"

    Get_weatherdata_now:(callback,cityid = @cityid)->
        # echo "Get_weatherdata_now"
        ajax(@url_nowweather_str,(xhr)=>
            try 
                localStorage.setItem("weatherdata_now_storage",xhr.responseText)
                callback()
            catch e
                echo "weatherdata_now xhr.responseText isnt JSON "
        )
    Get_weatherdata_more:(callback,cityid = @cityid)->
        # echo "Get_weatherdata_more"
        ajax(@url_moreweather_str,(xhr)=>
            try
                localStorage.setItem("weatherdata_more_storage",xhr.responseText)
                @weather_more_img()
                @weather_more_week()
                callback()
            catch e
                echo "weatherdata_more xhr.responseText isnt JSON "
        )

    weather_more_img:->
        weather_data_more = localStorage.getObject("weatherdata_more_storage")
        @img_front = [
            weather_data_more.weatherinfo.img_single,
            weather_data_more.weatherinfo.img1,
            weather_data_more.weatherinfo.img2,
            weather_data_more.weatherinfo.img3,
            weather_data_more.weatherinfo.img4,
            weather_data_more.weatherinfo.img5,
            weather_data_more.weatherinfo.img6,
            weather_data_more.weatherinfo.img7,
            weather_data_more.weatherinfo.img8,
            weather_data_more.weatherinfo.img9,
            weather_data_more.weatherinfo.img10,
            weather_data_more.weatherinfo.img11,
            weather_data_more.weatherinfo.img12
        ]
        @img_behind = [
            weather_data_more.weatherinfo.img_title_single,
            weather_data_more.weatherinfo.img_title1,
            weather_data_more.weatherinfo.img_title2,
            weather_data_more.weatherinfo.img_title3,
            weather_data_more.weatherinfo.img_title4,
            weather_data_more.weatherinfo.img_title5,
            weather_data_more.weatherinfo.img_title6,
            weather_data_more.weatherinfo.img_title7,
            weather_data_more.weatherinfo.img_title8,
            weather_data_more.weatherinfo.img_title9,
            weather_data_more.weatherinfo.img_title10,
            weather_data_more.weatherinfo.img_title11,
            weather_data_more.weatherinfo.img_title12
        ]
    weather_more_week:->
        i_week = 0
        week_name = ["\u661f\u671f\u65e5", "\u661f\u671f\u4e00", "\u661f\u671f\u4e8c", "\u661f\u671f\u4e09","\u661f\u671f\u56db", "\u661f\u671f\u4e94", "\u661f\u671f\u516d"]
        weather_data_more = localStorage.getObject("weatherdata_more_storage")
        while i_week < week_name.length
            break if weather_data_more.weatherinfo.week == week_name[i_week]
            i_week++
        @week_n = i_week