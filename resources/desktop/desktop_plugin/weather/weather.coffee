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
        
        @weather_now_pic = create_img("weather_now_pic", img_now_url_init, @element)

        @temperature_now = create_element("div", "temperature_now", @element)
        @temperature_now.textContent = "20°"

        more_city = create_element("div","more_city",@element)
        @city = create_element("div", "city", more_city)
        @city.textContent = "请选择城市"

        city_and_date = create_element("div", "city_and_date", @element)
        @date = create_element("div", "date", city_and_date)
        @date.textContent =  "正在加载中..." + "..."

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
        @more_city_img = create_img("more_city_img", @img_url_first + "ar.png", more_city)       
        @more_city_menu = create_element("div", "more_city_menu", @element)
        @chooseprov = create_element("select", "chooseprov", @more_city_menu)        
        @choosecity = create_element("select", "choosecity", @more_city_menu)
        close = create_element("div","close",@element)
        closebutton = create_img("closebutton",@img_url_first + "closebutton.png",close)

        close.addEventListener("mouseover", ->
            closebutton.style.display = "block"
            )
        close.addEventListener("mouseout", ->
            closebutton.style.display = "none"
            )        

        #when the mose click then leave ,close the weather widget
        closebutton.addEventListener("mouseup", =>
            @element.style.display = "none" #but the position still is there
            # kill(@element)
            # how to kill a class , then the widget position is null
            )

        @date.addEventListener("click", => 
            if @more_weather_menu.style.display == "none" 
                @more_weather_menu.style.display = "block"
                @more_city_menu.style.display = "none"
                @more_weather_menu.style.zIndex = "65535"    
            else 
                @more_weather_menu.style.display = "none"
                @more_city_menu.style.display = "none"
                @more_weather_menu.style.zIndex = "1"
        )        

        more_city.addEventListener("click", =>             
            if @more_city_menu.style.display == "none"
                @more_city_menu.style.display = "block"
                @chooseprov.style.display = "block"
                @choosecity.style.display = "block"
                @more_weather_menu.style.display = "none"
                @more_city_menu.style.zIndex = "65535"
            else 
                @more_city_menu.style.display = "none" 
                @chooseprov.style.display = "none"
                @choosecity.style.display = "none"                
                @more_weather_menu.style.display = "none"
                @more_city_menu.style.zIndex = "1"

            @chooseprov.size = 13
            @chooseprov.options.length = 0 #clear the prov option value
            for key of prov2city
                provincetemp = create_element("option", "provincetemp", @chooseprov)
                provincetemp.innerText = key
            # citytemp = create_element("option", "citytemp", @choosecity)
            # citytemp.innerText = "--市--"
            # for provin of allname.data
            #     provincetemp = create_element("option", "provincetemp", @chooseprov)
            #     provincetemp.innerText = allname.data[provin].省
        )


        @chooseprov.addEventListener("change", =>
            echo "prov change"
            provIndex = @chooseprov.selectedIndex #序号，取当前选中选项的序号 
            @provincevalue = @chooseprov.options[provIndex].value 
            echo @provincevalue
            # @chooseprov.size = 2

            
            if prov2city[@provincevalue].length < 13                
                @choosecity.size = prov2city[@provincevalue].length
                # @choosecity.size = allname.data[@provincevalue].市.length
            else @choosecity.size = 13
            @choosecity.options.length = 1 #clear the city option value
            for cityvalue in prov2city[@provincevalue]
                citytemp = create_element("option", "citytemp", @choosecity)
                citytemp.innerText = cityvalue
            # for provin of allname.data
            #     if allname.data[provin].省 is @provincevalue
            #         for ci of allname.data[provin].市
            #             citytemp = create_element("option", "citytemp", @choosecity)
            #             citytemp.innerText = allname.data[provin].市[ci].市名
            # chooseprov.options.length = 1;
            ) 
        @chooseprov.addEventListener("blur", ->
            echo "prov blur"            
            )
        @choosecity.addEventListener("blur", ->
            echo "city blur"
            )
        @chooseprov.addEventListener("focus", ->
            echo "prov focus"            
            )
        @choosecity.addEventListener("focus", ->
            echo "city focus"
            )
        @choosecity.addEventListener("change", =>
            echo "city change"
            # chooseprov.options.length = 1
            @chooseprov.style.display = "none"
            @choosecity.style.display = "none"

            cityIndex = @choosecity.selectedIndex #序号，取当前选中选项的序号 
            @cityvalue = @choosecity.options[cityIndex].value
            echo @cityvalue
 
            for provin of allname.data
                if allname.data[provin].省 is @provincevalue
                    # echo allname.data[provin].省
                    for ci of allname.data[provin].市
                        if allname.data[provin].市[ci].市名 is @cityvalue
                            # echo allname.data[provin].市[ci].市名
                            echo allname.data[provin].市[ci].编码
                            cityid = allname.data[provin].市[ci].编码
                            @cityurl = "http://m.weather.com.cn/data/"+cityid+".html"
                            auto_update = setInterval(@weathergui_update(@cityurl),10*60000)                            
            )

        @refresh.addEventListener("click", =>
            @refresh.style.backgroundColor = "gray"
            @weathergui_update(@cityurl)
        )

    ajax : (url, method, callback, asyn=true) ->
        xhr = new XMLHttpRequest()
        xhr.open(method, url, asyn)
        xhr.send(null)
        xhr.onreadystatechange = ->
            if (xhr.readyState == 4 and xhr.status == 200)
                echo "XMLHttpRequest received all data."
                callback?(xhr)                
            else if xhr.status isnt 200 
                echo "XMLHttpRequest can't receive data."   

    weathergui_init: =>
        window.loader.addcss('desktop_plugin/weather/weather.css', 'screen print').load()
        # cityid_init = 101010100  #101200101 #101010100
        # cityurl_init = "http://m.weather.com.cn/data/"+cityid_init+".html"    
        # @weathergui_update(cityurl_init)

    weathergui_update: (url)=>
        # echo "weathergui_update....."        
        @ajax( url , "GET", (xhr)=>
            localStorage.setItem(weather_data,xhr.responseText)
            weather_data = JSON.parse(localStorage.getItem(weather_data))
            localStorage.removeItem(weather_data)  
            week_name = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
            i_week = 0
            while i_week < week_name.length
                break if weather_data.weatherinfo.week is week_name[i_week]
                i_week++
            week_n = i_week
            @weather_now_pic.src = @img_url_first + "48/T" + weather_data.weatherinfo.img1 + weather_data.weatherinfo.img_title1 + ".png"
            str_data = weather_data.weatherinfo.date_y
            @date.textContent = str_data.substring(0,str_data.indexOf("年")) + "." + str_data.substring(str_data.indexOf("年")+1,str_data.indexOf("月"))+ "." + str_data.substring(str_data.indexOf("月") + 1,str_data.indexOf("日")) + weather_data.weatherinfo.week            
            temp_str = weather_data.weatherinfo.temp1
            i = temp_str.indexOf("℃")
            j = temp_str.lastIndexOf("℃")
            temper= ( parseInt(temp_str.substring(0,i)) + parseInt(temp_str.substring(i+2,j)) )/2
            @temperature_now.textContent = Math.round(temper) + "°"            
            @city.textContent = weather_data.weatherinfo.city

            @week1.textContent = week_name[week_n%7]
            @pic1.src = @img_url_first + "24/T" + weather_data.weatherinfo.img1 + weather_data.weatherinfo.img_title1 + ".png"
            @temperature1.textContent = weather_data.weatherinfo.temp1
            @week2.textContent = week_name[(week_n+1)%7]
            @pic2.src = @img_url_first + "24/T" + weather_data.weatherinfo.img3 + weather_data.weatherinfo.img_title3 + ".png"
            @temperature2.textContent = weather_data.weatherinfo.temp2
            @week3.textContent = week_name[(week_n+2)%7]
            @pic3.src = @img_url_first + "24/T" + weather_data.weatherinfo.img5 + weather_data.weatherinfo.img_title5 + ".png"
            @temperature3.textContent = weather_data.weatherinfo.temp3
            @week4.textContent = week_name[(week_n+3)%7]
            @pic4.src = @img_url_first + "24/T" + weather_data.weatherinfo.img7 + weather_data.weatherinfo.img_title7 + ".png"
            @temperature4.textContent = weather_data.weatherinfo.temp4
            @week5.textContent = week_name[(week_n+4)%7]
            @pic5.src = @img_url_first + "24/T" + weather_data.weatherinfo.img9 + weather_data.weatherinfo.img_title9 + ".png"
            @temperature5.textContent = weather_data.weatherinfo.temp5
            @week6.textContent = week_name[(week_n+5)%7]
            @pic6.src = @img_url_first + "24/T" + weather_data.weatherinfo.img11 + weather_data.weatherinfo.img_title11 + ".png"
            @temperature6.textContent = weather_data.weatherinfo.temp6

            @refresh.style.backgroundColor = null
        )