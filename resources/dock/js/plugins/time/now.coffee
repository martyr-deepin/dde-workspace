class Now
    constructor:()->

    force2bit:(n)->
        if n < 10 then "0#{n}" else "#{n}"

    hour: (max_hour=24, twobit=false)->
        hour = new Date().getHours()
        switch max_hour
            when 12
                if twobit then @force2bit(hour % 12) else "#{hour % 12}"
            when 24
                if twobit then @force2bit(hour) else "#{hour}"
    min:(twobit=true)->
        min = new Date().getMinutes()
        if twobit then @force2bit(min) else "#{min}"

    year:->
        new Date().getFullYear()

    month:->
        new Date().getMonth() + 1

    weekday:->
        new Date().getDay()

    date:->
        new Date().getDate()

    isMorning:->
        return @hour(24,true) - 12 < 0
