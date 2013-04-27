#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#Author:      yuanjq <yuanjq91@gmail.com>

class Weather extends Gadget
    weather_data = null
    xmlhttp = null
    cityurl = null
    cityid = null

    constructor: ->
        super
        cityid = 101010100
        cityurl = "http://m.weather.com.cn/data/"+cityid+".html"
        @weathergui_init()
        @LoadXMLDoc(cityurl)

        weather_now = create_element("div", "weather_now", @element)
        weather_now.style.position = "absolute"
        weather_now.style.top = "10px"
        weather_now.style.left = "20px"
        weather_now_pic = create_element("img", null, weather_now)
        weather_now_pic.src = "img/weather/" + weather_data.weatherinfo.img_title2 + ".png"
        weather_now_pic.style.width = "50px"
        weather_now_pic.style.height = "50px"
        weather_now_pic.draggable = false

        temperature_now = create_element("div", "temperature_now", @element)
        temperature_now.style.position = "absolute"
        temperature_now.style.top = "25px"
        temperature_now.style.left = "85px"
        temp_str = weather_data.weatherinfo.temp1
        i = temp_str.indexOf("℃")
        j = temp_str.lastIndexOf("℃")
        temper= ( parseInt(temp_str.substring(0,i)) + parseInt(temp_str.substring(i+2,j)) )/2
        temperature_now.textContent = temper + "°"
        temperature_now.style.fontSize = "32px"
        temperature_now.style.color = "white"

        city_and_date = create_element("div", "city_and_date", @element)
        city_and_date.style.position = "absolute"
        city_and_date.style.top = "15px"
        city_and_date.style.left = "140px"
        city = create_element("div", "city", city_and_date)
        city.textContent = weather_data.weatherinfo.city
        city.style.position = "relative"
        city.style.left = "20px"
        
        week_name = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
        date = create_element("div", "date", city_and_date)
        date.style.color = "white"
        date_val = new Date()
        week_n = date_val.getDay()
        date.textContent = date_val.toLocaleDateString() + week_name[(week_n)%7]
        #date_val = weather_data.weatherinfo.date_y
        #date.textContent =  weather_data.weatherinfo.date_y + weather_data.weatherinfo.week

        more_weather_menu = create_element("div", "more_weather_menu", @element)
        more_weather_menu.style.position = "absolute"
        more_weather_menu.style.left = "110px"
        more_weather_menu.style.top = "65px"
        more_weather_menu.style.width = "175px"
        more_weather_menu.style.display = "none"
        # more_weather_menu.style.Opacity = 50;

        
        #week_n = weather_data.weatherinfo.week
        second_day_weather_data = create_element("div", null, more_weather_menu)
        second_day_weather_data.style.backgroundColor = "deepskyblue"
        second_day_weather_data.style.opacity = 0.6

        week = create_element("a", null, second_day_weather_data)
        week.textContent = week_name[(week_n+1)%7]
        pic2 = create_element("img", null, second_day_weather_data)
        #pic2.src = "img/weather/cloudy.png"
        pic2.src = "img/weather/" + weather_data.weatherinfo.img_title4 + ".png"
        pic2.style.width = "30px"
        pic2.style.height = "30px"

        tempratue = create_element("a", null, second_day_weather_data)
        #tempratue.textContent = "10°~20°"
        tempratue.textContent = weather_data.weatherinfo.temp2

        third_day_weather_data = create_element("div", null, more_weather_menu)
        third_day_weather_data.style.backgroundColor = "palegoldenrod"
        third_day_weather_data.style.opacity = 0.6
        week = create_element("a", null, third_day_weather_data)
        week.textContent = week_name[(week_n+2)%7]
        pic3 = create_element("img", null, third_day_weather_data)
        #pic3.src = "img/weather/cloudy.png"
        pic3.src = "img/weather/" + weather_data.weatherinfo.img_title6 + ".png"
        pic3.style.width = "30px"
        pic3.style.height = "30px"
        tempratue = create_element("a", null, third_day_weather_data)
        #tempratue.textContent = "10°~20°"
        tempratue.textContent = weather_data.weatherinfo.temp3


        fourth_day_weather_data = create_element("div", null, more_weather_menu)
        fourth_day_weather_data.style.backgroundColor = "deepskyblue"
        fourth_day_weather_data.style.opacity = 0.6

        week = create_element("a", null, fourth_day_weather_data)
        week.textContent = week_name[(week_n+3)%7]
        pic4 = create_element("img", null, fourth_day_weather_data)
        # pic4.src = "img/weather/cloudy.png"
        pic4.src = "img/weather/" + weather_data.weatherinfo.img_title8 + ".png"
        pic4.style.width = "30px"
        pic4.style.height = "30px"
        tempratue = create_element("a", null, fourth_day_weather_data)
        #tempratue.textContent = "10°~20°"
        tempratue.textContent = weather_data.weatherinfo.temp4

        fifth_day_weather_data = create_element("div", null, more_weather_menu)
        fifth_day_weather_data.style.backgroundColor = "palegoldenrod"
        fifth_day_weather_data.style.opacity = 0.6

        week = create_element("a", null, fifth_day_weather_data)
        week.textContent = week_name[(week_n+4)%7]
        pic5 = create_element("img", null, fifth_day_weather_data)
        # pic5.src = "img/weather/cloudy.png"
        pic5.src = "img/weather/" + weather_data.weatherinfo.img_title10 + ".png"
        pic5.style.width = "30px"
        pic5.style.height = "30px"
        tempratue = create_element("a", null, fifth_day_weather_data)
        #tempratue.textContent = "10°~20°"
        tempratue.textContent = weather_data.weatherinfo.temp5

        sixth_day_weather_data = create_element("div", null, more_weather_menu)
        sixth_day_weather_data.style.backgroundColor = "deepskyblue"
        sixth_day_weather_data.style.opacity = 0.6

        week = create_element("a", null, sixth_day_weather_data)
        week.textContent = week_name[(week_n+5)%7]
        pic6 = create_element("img", null, sixth_day_weather_data)
        # pic6.src = "img/weather/cloudy.png"
        pic6.src = "img/weather/" + weather_data.weatherinfo.img_title12 + ".png"
        pic6.style.width = "30px"
        pic6.style.height = "30px"
        tempratue = create_element("a", null, sixth_day_weather_data)
        #tempratue.textContent = "10°~20°"
        tempratue.textContent = weather_data.weatherinfo.temp6

        seventeenth_day_weather_data = create_element("div", null, more_weather_menu)
        seventeenth_day_weather_data.style.backgroundColor = "palegoldenrod"
        seventeenth_day_weather_data.style.opacity = 0.6

        # week = create_element("a", null, seventeenth_day_weather_data)
        # week.textContent = week_name[(week_n+6)%7]
        # pic2 = create_element("img", null, seventeenth_day_weather_data)
        # pic2.src = "img/weather/cloudy.png"
        # pic2.style.width = "30px"
        # pic2.style.height = "30px"
        # tempratue = create_element("a", null, seventeenth_day_weather_data)
        # tempratue.textContent = "10°~20°"

        date.addEventListener("click", ->
            if more_weather_menu.style.display == "none" then more_weather_menu.style.display = "block"
            else more_weather_menu.style.display = "none"
        )
        ###
    do_buildmenu : ->
        menu = []
        menu.push([1, "北京"])
        menu.push([2, "上海"])
        menu.push([3, "广州"])

        return menu
        ###
        more_city = create_element("img", null, city)
        more_city.draggable = false  
        more_city.style.left = "/200px"      
        more_city.src = "img/weather/ar.png"
       
        more_city_menu = create_element("div", "more_city_menu", city)
        more_city_menu.style.display = "none"

        u1 = create_element("ul", null, more_city_menu)        
        l1 = create_element("li", null, u1)
        l2 = create_element("li", null, u1)
        l3 = create_element("li", null, u1)
        a1 = create_element("a", null, l1)
        a1.innerText = "北京"
        a2 = create_element("a", null, l2)
        a2.innerText = "上海"
        a3 = create_element("a", null, l3)
        a3.innerText = "广东"
        ###
        more_city_menu = create_element("div", "more_city_menu", city)
        city1 = create_element("option", null, more_city_menu)
        city1.textContext = "北京"
        city2 = create_element("option", null, more_city_menu)
        city2.textContent = "上海"
        city3 = create_element("option", null, more_city_menu)
        city3.textContent = "广州"
        ###
        # more_city_menu.style.backgroundColor = "white"
        # more_city_menu.style.border = "2px"
        # more_city_menu.style.borderColor = "buttonhighlight buttonshadow buttonhighlight"
        more_city.addEventListener("click", ->
            if more_city_menu.style.display == "none" then more_city_menu.style.display = "block"
            else more_city_menu.style.display = "none" )

    LoadXMLDoc: (url) ->
        
        xmlhttp = new XMLHttpRequest()
        xmlhttp.onreadystatechange = @state_Change
        xmlhttp.open("GET",url,true)
        xmlhttp.send(null)        

    state_Change: ->
        if xmlhttp.readystate ==4
            if xmlhttp.status == 200
                # localStorage.setObject("weather_data", Object)               
                localStorage.setItem(info,JSON.parse(xmlhttp.responseText))
                weather_data = JSON.parse(localStorage.getItem(info))
                localStorage.removeItem(info)
                # weather_data = JSON.parse(xmlhttp.responseText)
                @weathergui_update()
        else if xmlhttp.readystate == 0 
                @weathergui_init()
        else 
                # @weathergui_receiving()

    weathergui_init: ->
        weather_data= {
              "weatherinfo": {
                "city": "北京",
                "city_en": "beijing",
                "date_y": "2013年4月25日",
                "date": "",
                "week": "星期二",
                "fchh": "11",
                "cityid": "101010100",
                "temp1": "16℃~8℃",
                "temp2": "22℃~10℃",
                "temp3": "24℃~10℃",
                "temp4": "25℃~12℃",
                "temp5": "27℃~13℃",
                "temp6": "23℃~12℃",
                "tempF1": "60.8℉~46.4℉",
                "tempF2": "71.6℉~50℉",
                "tempF3": "75.2℉~50℉",
                "tempF4": "77℉~53.6℉",
                "tempF5": "80.6℉~55.4℉",
                "tempF6": "73.4℉~53.6℉",
                "weather1": "阵雨转晴",
                "weather2": "晴",
                "weather3": "晴",
                "weather4": "晴转多云",
                "weather5": "多云",
                "weather6": "多云转阴",
                "img1": "3",
                "img2": "0",
                "img3": "0",
                "img4": "99",
                "img5": "0",
                "img6": "99",
                "img7": "0",
                "img8": "1",
                "img9": "1",
                "img10": "99",
                "img11": "1",
                "img12": "2",
                "img_single": "3",
                "img_title1": "阵雨",
                "img_title2": "晴",
                "img_title3": "晴",
                "img_title4": "晴",
                "img_title5": "晴",
                "img_title6": "晴",
                "img_title7": "晴",
                "img_title8": "多云",
                "img_title9": "多云",
                "img_title10": "多云",
                "img_title11": "多云",
                "img_title12": "阴",
                "img_title_single": "阵雨",
                "wind1": "微风",
                "wind2": "北风3-4级转微风",
                "wind3": "微风",
                "wind4": "微风",
                "wind5": "微风",
                "wind6": "微风",
                "fx1": "微风",
                "fx2": "微风",
                "fl1": "小于3级",
                "fl2": "3-4级转小于3级",
                "fl3": "小于3级",
                "fl4": "小于3级",
                "fl5": "小于3级",
                "fl6": "小于3级",
                "index": "温凉",
                "index_d": "建议着夹衣或西服套装加薄羊毛衫等春秋服装。年老体弱者宜着夹衣或风衣加羊毛衫。",
                "index48": "温凉",
                "index48_d": "建议着夹衣加薄羊毛衫等春秋服装。体弱者宜着夹衣加羊毛衫。但昼夜温差较大，注意增减衣服。",
                "index_uv": "弱",
                "index48_uv": "中等",
                "index_xc": "不宜",
                "index_tr": "适宜",
                "index_co": "舒适",
                "st1": "15",
                "st2": "9",
                "st3": "22",
                "st4": "12",
                "st5": "25",
                "st6": "12",
                "index_cl": "较不宜",
                "index_ls": "不太适宜",
                "index_ag": "极易发"
              }
            }
        setInterval(@LoadXMLDoc(cityurl),50)
        console.log "weathergui_init"

    weathergui_receiving: ->
        text_receiving = "weathergui_receiving"
        console.log text_receiving
        # document.getElementByName("date").innerHTML = text_receiving

    weathergui_update: ->
        
        console.log "weathergui_update"
