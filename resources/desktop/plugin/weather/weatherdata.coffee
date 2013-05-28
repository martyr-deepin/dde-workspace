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

    ajax : (url, callback) ->
        xhr = new XMLHttpRequest()
        xhr.open("GET", url, true)
        xhr.send(null)
        xhr.onreadystatechange = ->
            if (xhr.readyState == 4 and xhr.status == 200)
                try
                    if xhr.responseText != ""
                        callback?(xhr)
                        echo "XMLHttpRequest receive all data."
                catch e
                    echo "xhr.responseText is error"
            else if xhr.status == 404
                echo "XMLHttpRequest can't find the url ."
            else if xhr.status == 0
                echo "your computer are not connected to the Internet"
            return xhr.status  

    Get_weatherdata_now:(callback,cityid = @cityid)->
        # echo "Get_weatherdata_now"
        @ajax(@url_nowweather_str,(xhr)=>
            # echo "weatherdata_now_storage:" + xhr.responseText
            try 
                localStorage.setItem("weatherdata_now_storage",xhr.responseText)
                callback()
            catch e
                echo "weatherdata_now xhr.responseText isnt JSON "
        )
    Get_weatherdata_more:(callback,cityid = @cityid)->
        # echo "Get_weatherdata_more"
        @ajax(@url_moreweather_str,(xhr)=>
            try
                localStorage.setItem("weatherdata_more_storage",xhr.responseText)
                callback()
            catch e
                echo "weatherdata_more xhr.responseText isnt JSON "
        )