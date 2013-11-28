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

class VoiceControl extends Widget
    myCanvas = null
    mouseover = false

    constructor:(x,y)->
        super
        document.body.appendChild(@element)
        @element.style.left = x
        @element.style.bottom = y

    show:->
        @element.style.display = "show"
    
    hide:->
        #echo "hide"
        @element.style.display = "none" if not mouseover
     
    drawVolume:(vol)->
        remove_element(myCanvas) if myCanvas
        myCanvas = create_element("canvas","myCanvas",@element)
        myCanvas.id = "myCanvas"
        #myCanvas.style.left = 0
        #myCanvas.style.top = 0
        myCanvas.style.width = "300px"
        myCanvas.style.top = "150px"
        c = document.getElementById("myCanvas")
        ctx = c.getContext("2d")

        volume = vol
        x0 = 0
        y0 = 0
        width = 50
        height = 50
        ctx.beginPath()
        ctx.moveTo(x0,y0)
        ctx.lineTo(x0 + width,y0)
        ctx.lineTo(x0,y0 + height)
        ctx.closePath()
        ctx.strokeStyle = "#DCDCDC"
        ctx.stroke()
        
        ctx.fillStyle = "#fff0ff"
        ctx.fillRect(x0,y0 + height - volume * height,x0 + width,y0 + height)
        
        ctx.globalCompositeOperation = "destination-in"

        ctx.beginPath()
        ctx.moveTo(x0,y0)
        ctx.lineTo(x0 + width,y0)
        ctx.lineTo(x0,y0 + height)
        ctx.closePath()
        ctx.strokeStyle = "#DCDCDC"
        ctx.stroke()
        ctx.fill()
        @element.style.display = "block"

    do_mouseover: (e)->
        #echo "menu over"
        mouseover = true
        @element.style.display = "block"
    
    do_mouseout: (e)->
        #echo "menu out"
        mouseover = false
        @hide()
    
   
    get_size: ->
        @element.style.display = "block"
        width = @element.clientWidth
        height = @element.clientHeight

        "width":width
        "height":height

    setVolume:(volume) =>
        audioplay.setVolume(volume)
        @drawVolume(@getVolume())

    getVolume:->
        audioplay.getVolume()

    do_mousewheel:(e)=>
        volume = @getVolume()
        if e.wheelDelta >= 120
            volume = volume + 0.1
        else if e.wheelDelta <= -120
            volume = volume - 0.1
        setVolume(volume)

        
class MediaControl extends Widget
    img_src_before = null
    up = null
    play = null
    next = null
    voice = null
    voicecontrol = null
    is_volume_control = false

    play_status = "play"
    voice_status = "voice"

    constructor:->
        super
        echo "audioplay"
        if not audio_play_status then return
        echo "MediaControl"
        img_src_before = "images/mediacontrol/"
        name = create_element("div","name",@element)
        name.textContent = audioplay.getTitle()
        control = create_element("div","control",@element)
        
        up = create_img("up",img_src_before + "up_normal.png",control)
        play = create_img("play",img_src_before + "#{play_status}_normal.png",control)
        next = create_img("next",img_src_before + "next_normal.png",control)
        voice = create_img("voice",img_src_before + "voice_normal.png",control)
        p = get_page_xy(voice, 0, 0)
        left = p.x + voice.clientHeight + 15
        top = p.y
        voicecontrol = new VoiceControl(left,top)
        
        @normal_hover_click_cb(up,
            img_src_before + "up_normal.png",
            img_src_before + "up_hover.png",
            img_src_before + "up_press.png",
            @media_up
        )
        @normal_hover_click_cb(next,
            img_src_before + "next_normal.png",
            img_src_before + "next_hover.png",
            img_src_before + "next_press.png",
            @media_next
        )
        @play_normal_hover_click_cb(play,@media_play)
        @voice_normal_hover_click_cb(voice)
        
    voice_normal_hover_click_cb: (el) ->
        el.addEventListener("mouseover",->
            is_volume_control = true
            el.src = img_src_before + voice_status + "_hover.png"
            volume = audioplay.getVolume()
            echo volume
            voicecontrol.drawVolume(volume)
            if volume == 0
                voice_status = "mute"
                qvoice.src = img_src_before + voice_status + "_hover.png"
        )
        el.addEventListener("mouseout",->
            is_volume_control = false
            voicecontrol.hide()
            el.src = img_src_before + voice_status + "_normal.png"
        )
        el.addEventListener("click",=>
            el.src = img_src_before + voice_status + "_press.png"
        )
        document.body.addEventListener("mousewheel",(e) =>
            if is_volume_control
                echo "is_volume_control"
        )
    play_normal_hover_click_cb: (el,click_cb) ->
        el.addEventListener("mouseover",->
            el.src = img_src_before + play_status + "_hover.png"
        )
        el.addEventListener("mouseout",->
            el.src = img_src_before + play_status + "_normal.png"
        )
        el.addEventListener("click",=>
            el.src = img_src_before + play_status + "_press.png"
            click_cb?()
        )
    normal_hover_click_cb: (el,normal,hover,click,click_cb) ->
        el.addEventListener("mouseover",->
            el.src = hover
        ) if hover
        el.addEventListener("mouseout",->
            el.src = normal
        ) if normal
        el.addEventListener("click",=>
            el.src = click
            click_cb?()
        ) if click

    media_up:->
        audioplay.Previous()

    media_play:=>
        if play_status is "play" then play_status = "pause"
        else play_status = "play"
        play.src = img_src_before + "#{play_status}_normal.png"
        echo play_status
        audioplay.PlayPause()
        

    media_next:->
        audioplay.Next()

