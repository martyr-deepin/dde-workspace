class AnalogClock extends Clock
    constructor:(setting, parent)->
        super(setting)

        @type = Clock.Type.Analog
        @time = create_element(tag:"div", class:"clock", parent)
        dail = create_img(src:"js/plugins/time/img/dail.png", class:"clock", @time)
        @hour_hand = create_img(src:"js/plugins/time/img/hour_hand.png", class:"clock", @time)
        @min_hand = create_img(src:"js/plugins/time/img/minute_hand.png", class:"clock", @time)
        @point = create_img(src:"js/plugins/time/img/point.png", class:"clock", @time)
        @point.style.zIndex = 20

    update:->
        now = new Now()
        hour = +now.hour(12,false)
        min = +now.min(false)
        hour_rotate = (hour+min/60)*30 # 360/12=30
        min_rotate = min * 6 # 360/60=6
        @hour_hand.style.webkitTransform = "rotate(#{hour_rotate}deg)"
        @min_hand.style.webkitTransform = "rotate(#{min_rotate}deg)"
