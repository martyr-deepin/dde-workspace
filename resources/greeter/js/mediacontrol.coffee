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

