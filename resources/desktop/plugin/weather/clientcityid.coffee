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

# use:(recommended)
#     Clientcityid = new ClientCityId()
#     cityid_client = localStorage.getItem("cityid_client_storage")
# or 
#     Clientcityid  = new ClientCityId())
#     cityid = Clientcityid.cityid
#     client_cityJSON = Clientcityid.client_cityjson
#     client_ip = clientid.ip

class ClientCityId
    @url_clientip = null
    @url_clientcityjsonbyip = null

    @client_ipstr = null
    @ip = null
    @client_cityjson = null
    @cityid_client = null

    constructor: ()->
        @url_clientip_str = @url_clientip()
        @Get_client_cityip(@url_clientip_str)

    url_clientip: ->
        return "http://int.dpool.sina.com.cn/iplookup/iplookup.php"
    url_clientcityjsonbyip:(ip)-> 
        return "http://int.dpool.sina.com.cn/iplookup/iplookup.php?format=js&ip=" + ip

    ajax : (url, callback) ->
        xhr = new XMLHttpRequest()
        xhr.open("GET", url, true)
        xhr.send(null)
        xhr.onreadystatechange = ->
            if (xhr.readyState == 4 and xhr.status == 200)
                if xhr.responseText isnt ""
                    callback?(xhr)
                    echo "XMLHttpRequest receive all data."
            # else if xhr.status is 404
            #     echo "XMLHttpRequest can't find the url ."
            # else if xhr.status is 0
            #     echo "your computer are not connected to the Internet"
            # return xhr.status  
    Get_client_cityip: (url_clientip = @url_clientip_str)=>
        if url_clientip isnt "" && url_clientip isnt null
            @ajax(url_clientip, (xhr)=>
                localStorage.setItem("client_ipstr_storage",xhr.responseText)
                @client_ipstr = localStorage.getItem("client_ipstr_storage")
                if @client_ipstr[0] is '1'
                    ip = @client_ipstr.slice(2,12)
                    echo "ip start :" + ip
                    localStorage.setItem("client_ipstart_storage",ip)
                    @ip = localStorage.getItem("client_ipstart_storage")
                    @Get_client_cityjsonByip(@ip)
                    return ip
                else 
                    echo "Get_client_cityip  can't get the right client ip"
                    return 0
            )
        else return 0

    Get_client_cityjsonByip: (ip = @ip)->
        if ip isnt "" && ip isnt null
            @url_clientcityjsonbyip = @url_clientcityjsonbyip(ip)
            @ajax(@url_clientcityjsonbyip, (xhr)=>
                client_cityjsonstr = xhr.responseText
                echo "client_cityjsonstr:"  + client_cityjsonstr
                remote_ip_info = JSON.parse(client_cityjsonstr.slice(21,client_cityjsonstr.length))
                echo "remote_ip_info:" + remote_ip_info
                echo "remote_ip_info.ret:" + remote_ip_info.ret
                echo "remote_ip_info.province:" + remote_ip_info.province
                if remote_ip_info.ret is 1
                    @Get_cityid_client_BycityJSON(remote_ip_info)
                    return remote_ip_info
                else 
                    echo "Get_client_cityjsonByip can't find the matched location right json by ip"
                    return 0
            )
        else return 0

    Get_cityid_client_BycityJSON:(client_cityjson = @client_cityjson)->
        if client_cityjson isnt "" && client_cityjson isnt null
            # echo "client_cityjson isnt null"
            for provin of allname.data
                if allname.data[provin].prov is client_cityjson.province
                    for ci of allname.data[provin].city
                        if allname.data[provin].city[ci].cityname is client_cityjson.city
                            cityid_client = allname.data[provin].city[ci].code
                            echo "cityid_client:"+ cityid_client
                            localStorage.setItem("cityid_storage",cityid_client)
                            @cityid_client = localStorage.getItem("cityid_storage")
                            new Weather()
                            return @cityid_client
        else return 0