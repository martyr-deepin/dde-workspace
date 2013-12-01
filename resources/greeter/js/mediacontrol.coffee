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
    num = null
    
    mouseover = false

    constructor:->
        super
        document.body.appendChild(@element)
        @element.style.display = "none"
    
    show:(x,y,position = "absolute")->
        @element.style.position = position
        @x = x
        @y = y
        @element.style.left = x
        @element.style.top = y
        @element.style.display = "block"
    
    hide:->
        @element.style.display = "none"
     
    drawVolume:(vol,width = 50,height = 50)->
        remove_element(myCanvas) if myCanvas
        myCanvas = create_element("canvas","myCanvas",@element)
        myCanvas.id = "myCanvas"
        x0 = 0
        y0 = 0
        myCanvas.style.width = width * 2
        myCanvas.style.height = height * 2
        myCanvas.style.position = "relative"
        myCanvas.style.left = "10px"
        c = document.getElementById("myCanvas")
        ctx = c.getContext("2d")
        
        # for the boder
        ctx.beginPath()
        ctx.moveTo(x0,y0)
        ctx.lineTo(x0 + width,y0)
        ctx.lineTo(x0,y0 + height)
        ctx.closePath()
        ctx.strokeStyle = "#DCDCDC"
        ctx.stroke()
        
        
        #dest
        ctx.beginPath()
        ctx.moveTo(x0,y0)
        ctx.lineTo(x0 + width,y0)
        ctx.lineTo(x0,y0 + height)
        ctx.closePath()
        ctx.strokeStyle = "#DCDCDC"
        ctx.stroke()
        ctx.fillStyle = "rgba(255,255,255,1.0)"
        ctx.fill()
        
        ctx.globalCompositeOperation = "source-in"

        #src
        ctx.fillStyle = "rgba(255,255,255,1.0)"
        ctx.fillRect(x0,y0 + height - vol * height,x0 + width,y0 + height)
        
        remove_element(num) if num
        num = create_element("div","num",@element)
        num.style.position = "relative"
        fontSize = 10
        num.style.fontSize = fontSize
        num.style.left = -25
        num.style.top = -80
        num.textContent = Math.round(vol * 100)

        @element.style.display = "block"

    do_mouseover: (e)->
        mouseover = true
        #@element.style.display = "block"
    
    do_mouseout: (e)->
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

    mousewheel:(e)=>
        volume = @getVolume()
        if e.wheelDelta >= 120
            volume = volume + 0.1
        else if e.wheelDelta <= -120
            volume = volume - 0.1
        @setVolume(volume)

        
class MediaControl extends Widget
    img_src_before = null
    
    name = null
    up = null
    play = null
    next = null
    voice= null

    voicecontrol = null
    is_volume_control = false

    play_status = "play"
    voice_status = "voice"

    constructor:->
        super
        if not audio_play_status then return
        img_src_before = "images/mediacontrol/"
        name = create_element("div","name",@element)
        name.textContent = audioplay.getTitle()
        control = create_element("div","control",@element)
        
        up = create_img("up",img_src_before + "up_normal.png",control)
        
        if audioplay.getPlaybackStatus() is "Playing" then play_status = "pause"
        else if audioplay.getPlaybackStatus() is "Paused" then play_status = "play"
        else play_status = "play"
        play = create_img("play",img_src_before + "#{play_status}_normal.png",control)
        next = create_img("next",img_src_before + "next_normal.png",control)
        voice = create_img("voice",img_src_before + "voice_normal.png",control)
        voicecontrol = new VoiceControl()
       
        setInterval(->
            name.textContent = audioplay.getTitle()
        ,1000)

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
        name.textContent = audioplay.getTitle()

    media_play:=>
        audioplay.mpris_dbus.PlayPause_sync()
        
        if audioplay.getPlaybackStatus() is "Playing" then play_status = "pause"
        else if audioplay.getPlaybackStatus() is "Paused" then play_status = "play"
        else play_status = "play"
        play.src = img_src_before + "#{play_status}_normal.png"
        

    media_next:->
        audioplay.Next()
        name.textContent = audioplay.getTitle()

    voice_normal_hover_click_cb: (el) ->
        el.addEventListener("mouseover",(e)=>
            is_volume_control = true
            p = e.srcElement
            x = p.x + voice.clientWidth
            y = p.y + 11
            voicecontrol.show(x,y)
            el.src = img_src_before + voice_status + "_hover.png"
            volume = audioplay.getVolume()
            voicecontrol.drawVolume(volume)
        )
        el.addEventListener("mouseout",->
            is_volume_control = false
            voicecontrol.hide()
            #voicecontrol.hide() if not voicecontrol.mouseover
            el.src = img_src_before + voice_status + "_normal.png"
        )
        #el.addEventListener("click",=>
            #el.src = img_src_before + voice_status + "_press.png"
        #)
        document.body.addEventListener("mousewheel",(e) =>
            if is_volume_control
                voicecontrol.mousewheel(e)
                if audioplay.getVolume() < 0.01 then voice_status = "mute"
                else voice_status = "voice"
                voice.src = img_src_before + voice_status + "_hover.png"
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

