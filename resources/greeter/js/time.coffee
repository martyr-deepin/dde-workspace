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

class TimeDate extends Widget
    constructor:->
        super
        inject_css(_b,"css/time.css")

    format_two_bit : (s) ->
        if s < 10
            return "0#{s}"
        else
            return s

    get_time_str : ->
        hours = @format_two_bit new Date().getHours()
        min = @format_two_bit new Date().getMinutes()
        return "#{hours}:#{min}"

    get_hours : ->
        return @format_two_bit new Date().getHours()

    get_min : ->
        return @format_two_bit new Date().getMinutes()

    get_date_str :(type = 1) ->
        month_list = [_("Jan"),_("Feb"),_("Mar"),_("Apr"),_("May"),_("Jun"),_("Jul"),_("Aug"),_("Sep"),_("Oct"),_("Nov"),_("Dec")]
        day_list = [_("Sun"),_("Mon"),_("Tue"),_("Wed"),_("Thu"),_("Fri"),_("Sat")]

        # 2014-2-17
        year = new Date().getFullYear()
        mon = new Date().getMonth() + 1
        #mon = month_list[new Date().getMonth()]
        date = new Date().getDate()
        
        # Monday
        day = day_list[new Date().getDay()]
        switch(type)
            when 1 then return "#{year}-#{mon}-#{date} #{day}"
            when 2 then return "#{year},#{mon},#{date} #{day}"

    get_c_date_str : ->
        if is_greeter
            return DCore.Greeter.get_date()
        else
            return DCore.Lock.get_date()


    show:->
        time = create_element("div","time",@element)
        date = create_element("div","date",@element)

        #time.innerText = @get_time_str()
        hours = create_element("span", "hours", time)
        hours.innerText = @get_hours()

        #colon = create_element("span", "timecolon", time)
        colon = create_element("span", "colon", time)
        colon.innerText = ":"

        min = create_element("span", "min", time)
        min.innerText = @get_min()

        date.innerText = @get_date_str()
        #date.innerText = @get_c_date_str()

        setInterval( =>
                hours.innerText = @get_hours()
                min.innerText = @get_min()
                return true
            , 1000)

        setInterval( =>
                date.innerText = @get_date_str()
                #date.innerText = @get_c_date_str()
                return true
            , 1000)

    import_css:(src)->
        inject_css(@element,src)
