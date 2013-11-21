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

class MediaControl extends Widget
    
    play_status = true

    constructor:->
        super
        img_src_before = "images/mediacontrol/"
        name = create_element("div","name",@element)
        name.textContent = "God is a girl"
        control = create_element("div","control",@element)
        
        up = create_img("up",img_src_before + "up_normal.png",control)
        play = create_img("play",img_src_before + "play_normal.png",control)
        next = create_img("next",img_src_before + "next_normal.png",control)
        voice = create_img("voice",img_src_before + "voice_normal.png",control)

        @normal_hover_click_cb(up,
            img_src_before + "up_normal.png",
            img_src_before + "up_hover.png",
            img_src_before + "up_press.png",
            @media_up
        )
        @normal_hover_click_cb(play,
            img_src_before + "play_normal.png",
            img_src_before + "play_hover.png",
            img_src_before + "play_press.png",
            @media_play
        )
        @normal_hover_click_cb(next,
            img_src_before + "next_normal.png",
            img_src_before + "next_hover.png",
            img_src_before + "next_press.png",
            @media_next
        )
        @normal_hover_click_cb(voice,
            img_src_before + "voice_normal.png",
            img_src_before + "voice_hover.png",
            img_src_before + "voice_press.png",
            @media_voice
        )
        

    normal_hover_click_cb: (el,normal,hover,click,click_cb) ->
        el.addEventListener("mouseover",->
            el.src = hover
        )
        el.addEventListener("mouseout",->
            el.src = normal
        )
        el.addEventListener("click",=>
            el.src = click
            click_cb?()
        )

    media_up:->
        echo "up"


    media_play:->



    media_next:->


    media_voice:->


