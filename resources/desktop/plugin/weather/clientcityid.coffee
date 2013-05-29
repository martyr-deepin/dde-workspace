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
        @url_clientip_str = "http://int.dpool.sina.com.cn/iplookup/iplookup.php"

    Get_client_cityip: (callback,url_clientip = @url_clientip_str)=>
        ajax(url_clientip, (xhr)=>
            try
                localStorage.setItem("client_ipstr_storage",xhr.responseText)
                @client_ipstr = localStorage.getItem("client_ipstr_storage")
                if @client_ipstr[0] == '1'
                    ip = @client_ipstr.slice(2,12)
                    echo "ip start :" + ip
                    localStorage.setItem("client_ipstart_storage",ip)
                    @ip = localStorage.getItem("client_ipstart_storage")
                    @Get_client_cityjsonByip(callback,@ip)
                    return ip
                else 
                    echo "Get_client_cityip  can't get the right client ip"
                    return 0
            catch e
                echo "Get_client_cityip error"
        )

    Get_client_cityjsonByip: (callback,ip = @ip)->
        @url_clientcityjsonbyip = "http://int.dpool.sina.com.cn/iplookup/iplookup.php?format=js&ip=" + ip
        ajax(@url_clientcityjsonbyip, (xhr)=>
            try
                client_cityjsonstr = xhr.responseText
                remote_ip_info = JSON.parse(client_cityjsonstr.slice(21,client_cityjsonstr.length))
                echo "remote_ip_info.ret:" + remote_ip_info.ret
                echo "remote_ip_info.province:" + remote_ip_info.province
                if remote_ip_info.ret == 1
                    @client_cityjson = remote_ip_info
                    @Get_cityid_client_BycityJSON(callback,@client_cityjson)
                    return remote_ip_info
                else 
                    echo "Get_client_cityjsonByip can't find the matched location right json by ip"
                    return 0
            catch e
                echo "Get_client_cityjsonByip error"
        )

    Get_cityid_client_BycityJSON:(callback,client_cityjson=@client_cityjson)->
        for provin of allname.data
            if allname.data[provin].prov == client_cityjson.province
                for ci of allname.data[provin].city
                    if allname.data[provin].city[ci].cityname == client_cityjson.city
                        cityid = allname.data[provin].city[ci].code
                        echo "cityid:"+ cityid
                        localStorage.setItem("cityid_storage",cityid)
                        callback()
