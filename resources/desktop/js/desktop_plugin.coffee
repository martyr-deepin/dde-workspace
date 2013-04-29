#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#Author:      yuanjq <yuanjq91@gmail.com>

<<<<<<< HEAD
class DesktopPlugin extends Widget
    constructor : (name, x, y, width, height) ->
        @set_id()
        pos = {x:0, y:0, width:0, height:0}
=======
class Gadget extends Widget
    constructor : (name, x, y, width, height) ->
        @set_id()
        super(@id)

        @element.draggable = true
        #icon_box = create_element("div", "item_icon", @element)
        ###
        @item_icon = document.createElement("img")
        icon_box.appendChild(@item_icon)
        ###

        pos = {x, y, width, height}
>>>>>>> 53a591a3c1455457090c531a742e1f94c55d094e
        pos.x = x
        pos.y = y
        pos.width = width
        pos.height = height
        save_position(@id, pos)
<<<<<<< HEAD
        super(@id)
        @element.draggable = true
=======

>>>>>>> 53a591a3c1455457090c531a742e1f94c55d094e
        return

    set_id : =>
        @id = "gadget"

    get_id : =>
        @id
<<<<<<< HEAD
        
=======

>>>>>>> 53a591a3c1455457090c531a742e1f94c55d094e
    do_mousedown : (evt) ->
        evt.stopPropagation()
        cancel_all_selected_stats()
        return

    do_dragstart : (evt) =>
        evt.stopPropagation()
<<<<<<< HEAD
        desktop_plugin_dragstart_handler(this, evt)
=======
        gadget_dragstart_handler(this, evt)
>>>>>>> 53a591a3c1455457090c531a742e1f94c55d094e
        return

    do_dragend : (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
<<<<<<< HEAD
        desktop_plugin_dragend_handler(this, evt)
=======
        gadget_dragend_handler(this, evt)
>>>>>>> 53a591a3c1455457090c531a742e1f94c55d094e
        return

    do_rightclick : (evt) ->
        evt.stopPropagation()
        evt.preventDefault()
        return

    move: (x, y) =>
        style = @element.style
        style.position = "absolute"
        style.left = x
        style.top = y
        return

<<<<<<< HEAD
=======

class Weather extends Gadget
    constructor: ->
        super
        ###
        @element.style.background = "url(img/weather/bg.png) no-repeat"
        @element.style.position = "absolute"
        @element.style.width = "286px"
        @element.style.height = "70px"
        ###
        weather_now = create_element("div", "weather_now", @element)
        weather_now.style.position = "absolute"
        weather_now.style.top = "5px"
        weather_now.style.left = "15px"
        weather_now_pic = create_element("img", null, weather_now)
        weather_now_pic.src = "img/weather/cloudy.png"
        weather_now_pic.style.width = "50px"
        weather_now_pic.style.height = "50px"
        weather_now_pic.draggable = false
        temperature_now = create_element("div", "temperature_now", @element)
        temperature_now.style.position = "absolute"
        temperature_now.style.top = "20px"
        temperature_now.style.left = "90px"
        temperature_now.textContent = "14°"
        temperature_now.style.fontSize = "32px"
        #temperature_now.style.fontWeight = "bold"
        temperature_now.style.color = "white"

        city_and_date = create_element("div", "city_and_date", @element)
        city_and_date.style.position = "absolute"
        city_and_date.style.top = "15px"
        city_and_date.style.left = "160px"
        city = create_element("div", "city", city_and_date)
        city.textContent = "武汉"
        more_city = create_element("img", null, city)
        more_city.draggable = false
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
        city1 = create_element("option", null, more_city_menu)
        city1.textContext = "北京"
        city2 = create_element("option", null, more_city_menu)
        city2.textContent = "上海"
        city3 = create_element("option", null, more_city_menu)
        city3.textContent = "广州"
        ###
        #more_city_menu.style.backgroundColor = "white"
        #more_city_menu.style.border = "2px"
        #more_city_menu.style.borderColor = "buttonhighlight buttonshadow buttonhighlight"
        more_city.addEventListener("click", ->
            if more_city_menu.style.display == "none" then more_city_menu.style.display = "block"
            else more_city_menu.style.display = "none"
        )

        date = create_element("div", "date", city_and_date)
        date.style.color = "white"
        date_val = new Date()
        date_fmt = create_element("a", null, date)
        date_fmt.innerText = @formatDate(date_val)
        
        week_name = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"]
        week_n = date_val.getDay()
        week = create_element("a", null, date)
        week.innerText = " " + week_name[date_val.getDay()%7]

        more_weather_menu = create_element("div", "more_weather_menu", @element)
        more_weather_menu.style.position = "absolute"
        more_weather_menu.style.left = "76px"
        more_weather_menu.style.top = "65px"
        more_weather_menu.style.width = "175px"
        more_weather_menu.style.display = "none"

        second_day_weather_info = create_element("div", null, more_weather_menu)
        second_day_weather_info.style.backgroundColor = "white"
        second_day_weather_info.style.opacity = 0.3

        week = create_element("a", null, second_day_weather_info)
        week.textContent = week_name[(week_n+1)%7]
        pic2 = create_element("img", null, second_day_weather_info)
        pic2.src = "img/weather/cloudy.png"
        pic2.style.width = "30px"
        pic2.style.height = "30px"

        tempratue = create_element("a", null, second_day_weather_info)
        tempratue.textContent = "10°~20°"

        third_day_weather_info = create_element("div", null, more_weather_menu)
        third_day_weather_info.style.backgroundColor = "black"
        third_day_weather_info.style.opacity = 0.3
        week = create_element("a", null, third_day_weather_info)
        week.textContent = week_name[(week_n+2)%7]
        pic2 = create_element("img", null, third_day_weather_info)
        pic2.src = "img/weather/cloudy.png"
        pic2.style.width = "30px"
        pic2.style.height = "30px"
        tempratue = create_element("a", null, third_day_weather_info)
        tempratue.textContent = "10°~20°"

        fourth_day_weather_info = create_element("div", null, more_weather_menu)
        fourth_day_weather_info.style.backgroundColor = "white"
        fourth_day_weather_info.style.opacity = 0.3

        week = create_element("a", null, fourth_day_weather_info)
        week.textContent = week_name[(week_n+3)%7]
        pic2 = create_element("img", null, fourth_day_weather_info)
        pic2.src = "img/weather/cloudy.png"
        pic2.style.width = "30px"
        pic2.style.height = "30px"
        tempratue = create_element("a", null, fourth_day_weather_info)
        tempratue.textContent = "10°~20°"

        fifth_day_weather_info = create_element("div", null, more_weather_menu)
        fifth_day_weather_info.style.backgroundColor = "black"
        fifth_day_weather_info.style.opacity = 0.3

        week = create_element("a", null, fifth_day_weather_info)
        week.textContent = week_name[(week_n+4)%7]
        pic2 = create_element("img", null, fifth_day_weather_info)
        pic2.src = "img/weather/cloudy.png"
        pic2.style.width = "30px"
        pic2.style.height = "30px"
        tempratue = create_element("a", null, fifth_day_weather_info)
        tempratue.textContent = "10°~20°"

        sixth_day_weather_info = create_element("div", null, more_weather_menu)
        sixth_day_weather_info.style.backgroundColor = "white"
        sixth_day_weather_info.style.opacity = 0.3

        week = create_element("a", null, sixth_day_weather_info)
        week.textContent = week_name[(week_n+5)%7]
        pic2 = create_element("img", null, sixth_day_weather_info)
        pic2.src = "img/weather/cloudy.png"
        pic2.style.width = "30px"
        pic2.style.height = "30px"
        tempratue = create_element("a", null, sixth_day_weather_info)
        tempratue.textContent = "10°~20°"

        seventeenth_day_weather_info = create_element("div", null, more_weather_menu)
        seventeenth_day_weather_info.style.backgroundColor = "black"
        seventeenth_day_weather_info.style.opacity = 0.3

        week = create_element("a", null, seventeenth_day_weather_info)
        week.textContent = week_name[(week_n+6)%7]
        pic2 = create_element("img", null, seventeenth_day_weather_info)
        pic2.src = "img/weather/cloudy.png"
        pic2.style.width = "30px"
        pic2.style.height = "30px"
        tempratue = create_element("a", null, seventeenth_day_weather_info)
        tempratue.textContent = "10°~20°"

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

    formatDate : (date) ->
        year = date.getYear() + 1900
        month = date.getMonth()+1
        day = date.getDate()
        ft = year + "." + month + "." + day
        return ft



>>>>>>> 53a591a3c1455457090c531a742e1f94c55d094e
