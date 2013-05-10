#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 bluth
#
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#Maintainer:  bluth <yuanchenglu@linuxdeepin.com>

class Weather
    constructor: ->
        @img_url_first = "desktop_plugin/weather/img/"
        week_init = "星期日"
        img_now_url_init = @img_url_first + "48/T" + "0晴" + ".png"
        img_more_url_init = @img_url_first + "24/T" + "0晴" + ".png"

        @element = create_element("div","Weather",null)
        @element.draggable = true

        @weathergui_init() 
        left_div = create_element("div", "left_div", @element)
        @weather_now_pic = create_img("weather_now_pic", img_now_url_init, left_div)

        right_div = create_element("div","right_div",@element)
        temperature_now = create_element("div", "temperature_now", right_div)
        @temperature_now_minus = create_element("div", "temperature_now_minus", temperature_now)
        @temperature_now_minus.textContent = "-"
        @temperature_now_number = create_element("div", "temperature_now_number", temperature_now)
        @temperature_now_number.textContent = "3°"

        city_and_date = create_element("div","city_and_date",right_div)
        city = create_element("div","city",city_and_date)
        @city_now = create_element("div", "city_now", city)
        @city_now.textContent = "请选择城市"
        @more_city_img = create_img("more_city_img", @img_url_first + "ar.png", city)
        @more_city_menu = create_element("div", "more_city_menu", @element)
        
        @date = create_element("div", "date", city_and_date)
        @date.textContent =  "正在加载中..." + " " +"..."

        @more_weather_menu = create_element("div", "more_weather_menu", @element)

        @first_day_weather_data = create_element("div", "first_day_weather_data", @more_weather_menu)
        @week1 = create_element("a", "week1", @first_day_weather_data)
        @week1.textContent = week_init
        @pic1 = create_img("pic1", img_more_url_init, @first_day_weather_data)
        @temperature1 = create_element("a", "temperature1", @first_day_weather_data)
        @temperature1.textContent = "22℃~10℃"

        @second_day_weather_data = create_element("div", "second_day_weather_data", @more_weather_menu)
        @week2 = create_element("a", "week2", @second_day_weather_data)
        @week2.textContent = week_init
        @pic2 = create_img("pic2", img_more_url_init, @second_day_weather_data)
        @temperature2 = create_element("a", "temperature2", @second_day_weather_data)
        @temperature2.textContent = "22℃~10℃"

        @third_day_weather_data = create_element("div", "third_day_weather_data", @more_weather_menu)
        @week3 = create_element("a", "week3", @third_day_weather_data)
        @week3.textContent = week_init
        @pic3 = create_img("pic3", img_more_url_init, @third_day_weather_data)
        @temperature3 = create_element("a", "temperature3", @third_day_weather_data)
        @temperature3.textContent = "22℃~10℃"

        @fourth_day_weather_data = create_element("div", "fourth_day_weather_data", @more_weather_menu)
        @week4 = create_element("a", "week4", @fourth_day_weather_data)
        @week4.textContent = week_init
        @pic4 = create_img("pic4", img_more_url_init, @fourth_day_weather_data)
        @temperature4 = create_element("a", "temperature4", @fourth_day_weather_data)
        @temperature4.textContent = "22℃~10℃"

        @fifth_day_weather_data = create_element("div", "fifth_day_weather_data", @more_weather_menu)
        @week5 = create_element("a", "week5", @fifth_day_weather_data)
        @week5.textContent = week_init
        @pic5 = create_img("pic5", img_more_url_init, @fifth_day_weather_data)
        @temperature5 = create_element("a", "temperature5", @fifth_day_weather_data)
        @temperature5.textContent = "22℃~10℃"

        @sixth_day_weather_data = create_element("div", "sixth_day_weather_data", @more_weather_menu)
        @week6 = create_element("a", "week6", @sixth_day_weather_data)
        @week6.textContent = week_init
        @pic6 = create_img("pic6", img_more_url_init, @sixth_day_weather_data)
        @temperature6 = create_element("a", "temperature6", @sixth_day_weather_data)
        @temperature6.textContent = "22℃~10℃"

        @refresh = create_img("refresh", @img_url_first + "refresh.png", @element)

        @chooseprov = create_element("select", "chooseprov", @more_city_menu)        
        @choosecity = create_element("select", "choosecity", @more_city_menu)
        @choosedist = create_element("select", "choosedist", @more_city_menu)

        @contextmenu = create_element("div","contextmenu",@element)
        weather_close  = create_element("div","weather_close",@contextmenu)
        refresh_context = create_element("div","refresh_context",@contextmenu)
        feedback = create_element("div","feedback",@contextmenu)
        about = create_element("div","about",@contextmenu)
        weather_close.innerText = "关闭"
        refresh_context.innerText = "刷新"
        feedback.innerText = "反馈"
        about.innerText = "关于"

        @date.addEventListener("click", => 
            if @more_weather_menu.style.display == "none" 
                @more_weather_menu.style.display = "block"
                @more_city_menu.style.display = "none"
                @more_weather_menu.style.zIndex = "65535"    
            else 
                @more_weather_menu.style.display = "none"
                @more_city_menu.style.display = "none"
                @more_weather_menu.style.zIndex = "0"
        )        

        city.addEventListener("click", =>     
            @flag_more_city_menu_click = 0                    
            if @more_city_menu.style.display == "none"
                @more_city_menu.style.display = "block"
                @more_weather_menu.style.display = "none"
                @more_city_menu.style.zIndex = "65535"
                # set 2 seconds no choose province to hide the more_city_menu option ,
                # but if you click the citychoose menu ,it will not hide
                @display_city_menu_id = setTimeout( => 
                    @more_city_menu.style.display = "none"
                ,4000)
            else 
                @more_city_menu.style.display = "none" 
                @more_weather_menu.style.display = "none"
                @more_city_menu.style.zIndex = "0"
            @chooseprov.options.length = 0 #clear the prov option value
            provinit = create_element("option","provinit",@chooseprov)
            provinit.innerText = "--省--"
            provinit.selected = "true"
            i = 0
            while i < cities.length
                @chooseprov.options.add(new Option(cities[i].name, cities[i++].id))
            @chooseprov.size = (if (@chooseprov.options.length < 13) then @chooseprov.options.length else 13)    
            @choosecity.size = 1
            @choosecity.options.length = 0 #clear the city option value
            cityinit = create_element("option", "cityinit", @choosecity)
            cityinit.innerText = "--市--"
            cityinit.selected = "true"
            @choosedist.size = 1
            @choosedist.options.length = 0 #clear the city option value
            distinit = create_element("option", "distinit", @choosedist)
            distinit.innerText = "--县--"
            distinit.selected = "true"
        )
        @more_city_menu.addEventListener("click", =>
            # but if you click the citychoose menu ,it will not hide
            clearTimeout(@display_city_menu_id)
            )
        @chooseprov.addEventListener("change", =>
            echo "prov change"
            provIndex = @chooseprov.selectedIndex
            provvalue = @chooseprov.options[provIndex].value 
            data = @read_data_from_json(provvalue)
            ) 

        @element.addEventListener("click" , =>
            @contextmenu.style.display = "none"
            )
        contextmenu_times = 0
        @element.addEventListener("contextmenu",  (evt) => 
            @more_weather_menu.style.display = "none"
            @more_city_menu.style.display = "none"
            contextmenu_times++
            # echo "contextmenu_times:" + contextmenu_times 
            if contextmenu_times%2 is 1  
                bottom_distance =  window.screen.availHeight - @element.getBoundingClientRect().bottom
                echo "bottom_distance:" + bottom_distance
                if bottom_distance < 200 
                    @contextmenu.style.top = 0
                @contextmenu.style.display = "block"
            else
                @contextmenu.style.display= "none"   
            )

        weather_close.addEventListener("click", =>
            @element.style.display = "none"
            )
        refresh_context.addEventListener("click", =>
            @refresh.style.backgroundColor = "gray"
            @weathergui_update(@cityid)
            )
        feedback.addEventListener("click", ->
            feedbackmsg = prompt("亲～谢谢您的反馈～～","")
            echo feedbackmsg
            )
        about.addEventListener("click", ->
            str = "深度天气插件1.0.0" + "\n" +
                  "Author:bluth" + "\n" +
                  "Copyright (c) 2011 ~ 2012 Deepin, Inc."  + "\n" + 
                  "www.linuxdeepin.com"
            alert str
            alert.title = "about"
            )
        @refresh.addEventListener("click", =>
            @refresh.style.backgroundColor = "gray"
            @weathergui_update(@cityid)
        )
        
    read_data_from_json: (id) =>
        xhr = new XMLHttpRequest()
        url = "desktop_plugin/weather/city/" + id + ".json"
        xhr.open("GET", url, true)
        xhr.send(null)
        xhr.onreadystatechange = =>
            if (xhr.readyState == 4)
                data = JSON.parse(xhr.responseText);
                @cityadd(data[id].data)

    cityadd: (data) =>
        @choosecity.options.length = 1
        for i of data
            @choosecity.options.add(new Option(data[i].name, i))
        @choosecity.size = (if (@choosecity.options.length < 13) then @choosecity.options.length else 13)   
        echo "@choosecity.size:" + @choosecity.size
        @choosecity.onchange = =>
            cityIndex = @choosecity.selectedIndex
            cityvalue = @choosecity.options[cityIndex].value
            @distadd(data[cityvalue].data)
    
    distadd: (data) =>
        @choosedist.options.length = 1
        for i of data
            @choosedist.options.add(new Option(data[i].name, i))
        @choosedist.size = (if (@choosedist.options.length < 13) then @choosedist.options.length else 13)
        echo "@choosedist.size:" + @choosedist.size
        @choosedist.onchange = =>
            distIndex = @choosedist.selectedIndex 
            distvalue = @choosedist.options[distIndex].value
            @cityid = data[distvalue].data
            echo "@cityid " + @cityid 
            @more_city_menu.style.display = "none"
            setInterval(@weathergui_update(@cityid),1800000)# half  hour update once

    ajax : (url, method, callback, asyn=true) =>
        xhr = new XMLHttpRequest()
        xhr.open(method, url, asyn)
        xhr.send(null)
        xhr.onreadystatechange = =>
            if (xhr.readyState == 4 and xhr.status == 200)
                echo "XMLHttpRequest received all data."
                callback?(xhr)                
            else if xhr.status isnt 200 
                echo "XMLHttpRequest can't receive data."
    get_client_cityid : =>
        ip_url = "http://int.dpool.sina.com.cn/iplookup/iplookup.php"
        # ip_url = "http://61.4.185.48:81/g/"
        @ajax(ip_url,"GET", (xhr)=>
                localStorage.setItem(client_ip,xhr.responseText)
                client_ip = localStorage.getItem(client_ip)
                # localStorage.removeItem(client_ip)
                str = client_ip.toString()
                echo str
                str_provcity = str.slice(str.indexOf("国")+2,-6)
                echo str_provcity.indexOf(" ")#2
                prov_client = str_provcity.slice(0,2)
                city_client = str_provcity.slice(3)
                echo "prov_client:" + prov_client
                echo "city_client:" + city_client
                for provin of allname.data
                    if allname.data[provin].省 is prov_client
                        for ci of allname.data[provin].市
                            if allname.data[provin].市[ci].市名 is city_client
                                echo allname.data[provin].市[ci].编码
                                @cityid = allname.data[provin].市[ci].编码
                                @weathergui_update(@cityid)
            )
    weathergui_init: =>
        window.loader.addcss('desktop_plugin/weather/weather.css', 'screen print').load()
        @get_client_cityid()

    weathergui_update: (cityid)=>
        localStorage.setItem(cityid,cityid)
        cityid = localStorage.getItem(cityid)
        # alert "weathergui_update....."  
        now_weather_url = "http://www.weather.com.cn/data/sk/" + cityid + ".html"
        weather_url = "http://m.weather.com.cn/data/"+cityid+".html"
        @ajax(now_weather_url , "GET" , (xhr) =>
            localStorage.setItem(weather_data_now,xhr.responseText)
            weather_data_now = JSON.parse(localStorage.getItem(weather_data_now))
            temp_now = weather_data_now.weatherinfo.temp
            @time_update = weather_data_now.weatherinfo.time
            echo "temp_now:" + temp_now
            echo "@time_update:" + @time_update
            @city_now.textContent = weather_data_now.weatherinfo.city
            if temp_now < -10
                @temperature_now_minus.style.opacity = 0.8
                @temperature_now_number.textContent = -temp_now + "°"
            else
                @temperature_now_minus.style.opacity = 0
                @temperature_now_number.textContent = temp_now + "°"            
            )   
        @ajax( weather_url , "GET", (xhr) =>
            localStorage.setItem(weather_data,xhr.responseText)
            weather_data = JSON.parse(localStorage.getItem(weather_data))
            # localStorage.removeItem(weather_data)  
            @weather_data = weather_data
            week_name = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
            i_week = 0
            while i_week < week_name.length
                break if weather_data.weatherinfo.week is week_name[i_week]
                i_week++
            week_n = i_week
            str_data = weather_data.weatherinfo.date_y
            @date.textContent = str_data.substring(0,str_data.indexOf("年")) + "." + str_data.substring(str_data.indexOf("年")+1,str_data.indexOf("月"))+ "." + str_data.substring(str_data.indexOf("月") + 1,str_data.indexOf("日")) + weather_data.weatherinfo.week 
            @weather_now_pic.src = @img_url_first + "48/T" + weather_data.weatherinfo.img_single + weather_data.weatherinfo.img_title_single + ".png"

            @week1.textContent = week_name[week_n%7]
            @pic1.src = @weather_more_pic_src(1)
            @temperature1.textContent = weather_data.weatherinfo.temp1
            @week2.textContent = week_name[(week_n+1)%7]
            @pic2.src = @weather_more_pic_src(2)
            @temperature2.textContent = weather_data.weatherinfo.temp2
            @week3.textContent = week_name[(week_n+2)%7]
            @pic3.src = @weather_more_pic_src(3)
            @temperature3.textContent = weather_data.weatherinfo.temp3
            @week4.textContent = week_name[(week_n+3)%7]
            @pic4.src = @weather_more_pic_src(4)
            @temperature4.textContent = weather_data.weatherinfo.temp4
            @week5.textContent = week_name[(week_n+4)%7]
            @pic5.src = @weather_more_pic_src(5)
            @temperature5.textContent = weather_data.weatherinfo.temp5
            @week6.textContent = week_name[(week_n+5)%7]
            @pic6.src = @weather_more_pic_src(6)
            @temperature6.textContent = weather_data.weatherinfo.temp6

            @refresh.style.backgroundColor = null
        )
    weather_more_pic_src:(i) =>
        i = i*2 -1
        weather_data = @weather_data
        src = null
        time = new Date()
        hours_now = time.getHours()
        echo "hours_now:" + hours_now
        img_front = [
            weather_data.weatherinfo.img_single,
            weather_data.weatherinfo.img1,
            weather_data.weatherinfo.img2,
            weather_data.weatherinfo.img3,
            weather_data.weatherinfo.img4,
            weather_data.weatherinfo.img5,
            weather_data.weatherinfo.img6,
            weather_data.weatherinfo.img7,
            weather_data.weatherinfo.img8,
            weather_data.weatherinfo.img9,
            weather_data.weatherinfo.img10,
            weather_data.weatherinfo.img11,
            weather_data.weatherinfo.img12  
        ]
        img_behind = [
            weather_data.weatherinfo.img_title_single,
            weather_data.weatherinfo.img_title1,
            weather_data.weatherinfo.img_title2,
            weather_data.weatherinfo.img_title3,
            weather_data.weatherinfo.img_title4,
            weather_data.weatherinfo.img_title5,
            weather_data.weatherinfo.img_title6,
            weather_data.weatherinfo.img_title7,
            weather_data.weatherinfo.img_title8,
            weather_data.weatherinfo.img_title9,
            weather_data.weatherinfo.img_title10,
            weather_data.weatherinfo.img_title11,
            weather_data.weatherinfo.img_title12                        
        ]
        
        j = 0
        # while j < img_front.length
        #     if img_front[j+1] is "99" 
        #         echo "99"
        #         img_front[j+1] = img_front[j]
        #     j++
        if img_front[i+1] is "99" 
            echo "99"
            img_front[i+1] = img_front[i]
        echo "img_front: " + img_front
        if hours_now < 12                 
            src = @img_url_first + "24/T" + img_front[i] + img_behind[i] + ".png"
        else src = @img_url_first + "24/T" + img_front[i+1] + img_behind[i+1] + ".png"
        echo src
        return src