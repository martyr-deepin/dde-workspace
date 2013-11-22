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
    voice = 50
    constructor:->
        super
        document.body.appendChild(@element)
    
    append:(el)->
        parent = el
        parent.appendChild(@element)
    destory:->
        remove_element(@element)

    do_mouseover: (e)->
        #echo "menu over"
        mouseover = true
        @element.style.display = "block"
    
    do_mouseout: (e)->
        #echo "menu out"
        mouseover = false
        @hide()
    
    show: (left, bottom)->
        #echo "show"
        document.body.appendChild(@element) if not parent?
        @element.style.left = left
        @element.style.bottom = bottom
        @element.style.display = "block"

    hide:->
        #echo "hide"
        @element.style.display = "none" if not mouseover
    
    get_size: ->
        @element.style.display = "block"
        width = @element.clientWidth
        height = @element.clientHeight

        "width":width
        "height":height

    voice_control:=>
        voice = 50

    get_voice:->
        return voice

class MediaControl extends Widget
    img_src_before = null
    up = null
    play = null
    next = null
    voice = null
    voicecontrol = null

    play_status = "play"
    voice_status = "voice"
    
    constructor:->
        super
        img_src_before = "images/mediacontrol/"
        name = create_element("div","name",@element)
        name.textContent = "God is a girl"
        control = create_element("div","control",@element)
        
        up = create_img("up",img_src_before + "up_normal.png",control)
        play = create_img("play",img_src_before + "#{play_status}_normal.png",control)
        next = create_img("next",img_src_before + "next_normal.png",control)
        voice = create_img("voice",img_src_before + "voice_normal.png",control)
        voicecontrol = new VoiceControl()
        
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
        @voice_normal_hover_click_cb(voice,@media_voice)
        
    voice_normal_hover_click_cb: (el,hover_cb) ->
        el.addEventListener("mouseover",->
            el.src = img_src_before + voice_status + "_hover.png"
            hover_cb?()
        )
        el.addEventListener("mouseout",->
            el.src = img_src_before + voice_status + "_normal.png"
        )
        el.addEventListener("click",=>
            el.src = img_src_before + voice_status + "_press.png"
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
        echo "up"


    media_play:=>
        if play_status is "play" then play_status = "pause"
        else play_status = "play"
        play.src = img_src_before + "#{play_status}_normal.png"
        echo play_status
        

    media_next:->


    media_voice:->
        voicecontrol.element.style.display = "block"
        if voicecontrol.get_voice() == 0
            voice_status = "mute"
            voice.src = img_src_before + voice_status + "_hover.png"

