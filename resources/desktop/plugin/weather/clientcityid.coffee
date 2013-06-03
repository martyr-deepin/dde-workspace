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

class ClientCityId
    constructor: ->
        @url_clientcity_json = "http://int.dpool.sina.com.cn/iplookup/iplookup.php?format=js&ip="

    Get_client_cityid: (callback)->
        ajax(@url_clientcity_json, (xhr)=>
            try
                client_cityjsonstr = xhr.responseText
                remote_ip_info = JSON.parse(client_cityjsonstr.slice(21,client_cityjsonstr.length))
                # echo "remote_ip_info.ret:" + remote_ip_info.ret
                # echo "remote_ip_info.city:" + remote_ip_info.city
                if remote_ip_info.ret == 1
                    for provin of allname.data
                        if allname.data[provin].prov == remote_ip_info.province
                            for ci of allname.data[provin].city
                                if allname.data[provin].city[ci].cityname == remote_ip_info.city
                                    cityname_client = remote_ip_info.city
                                    localStorage.setItem("cityname_client_storage",cityname_client)
                                    
                                    cityid_client = allname.data[provin].city[ci].code
                                    # echo "cityid_client:"+ cityid_client
                                    localStorage.setItem("cityid_storage",cityid_client)
                                    callback()

                else 
                    echo "Get_client_cityid can't find the matched location right json by ip"
                    return 0
            catch e
                echo "Get_client_cityid error"
        )

