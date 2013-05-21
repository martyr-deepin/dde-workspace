ip_url1 = ->
    return "http://int.dpool.sina.com.cn/iplookup/iplookup.php"
ip_url2 = (ip)-> 
    return "http://int.dpool.sina.com.cn/iplookup/iplookup.php?format=js&ip=" + ip
now_weather_url = (cityid)-> 
    return "http://www.weather.com.cn/data/sk/"+ cityid + ".html" 
more_weather_url = (cityid)->
    return "http://m.weather.com.cn/data/" + cityid + ".html"

