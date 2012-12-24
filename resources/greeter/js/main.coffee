#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
#Maintainer:  LongWei <yilang2007lw@gmail.com>
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

format_two_bit = (s) ->
    if s < 10
        return "0#{s}"
    else
        return s

get_time_str = ->

	today = new Date()
	hours = format_two_bit today.getHours()
	min = format_two_bit today.getMinutes()
	return "#{hours}:#{min}"

get_date_str = ->

    month_list = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
	day_list = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]

	now = new Date()

	day = day_list[now.getDay()]
	mon = month_list[now.getMonth()]
	date = now.getDate()
	year = now.getFullYear()

	return "#{day}, #{mon} #{date}, #{year}"

show_suspend = ->
    return Greeter.get_can_suspend()

show_hibernate = ->
    return Greeter.get_can_hibernate()

show_restart = ->
	return Greeter.get_can_restart()

show_shutdown = ->
    return Greeter.get_can_shutdown()

suspend = ->
	return Greeter.suspend()

hibernate = ->
    return Greeter.hibernate()

restart = ->
	return Greeter.restart()

shutdown = ->
    return Greeter.shutdown()	 	 		  	  		  	  	  	 	 	   	   	   


class Time extends Widget
    constructor: (@id)->
        super
        document.body.appendChild(@element)
		@time = get_time_str()
		@date = get_date_str()
		@element.innerHTML = "
		<div class=Time01>#{@time}</div>
		<div class=TIme02>#{@date}</div>
		"
    hide: ->
        @element.style.display = "none"

Time_container = new Time("time")

class Ver extends Widget
    constructor: (@id)->
        super
	    document.body.appendChild(@element)





