#Copyright (c) 2011 ~ 2014 Deepin, Inc.
#              2011 ~ 2014 bluth
#
#encoding: utf-8
#Author:      bluth <yuanchenglu@linuxdeepin.com>
#Maintainer:  bluth <yuanchenglu@linuxdeepin.com>
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

class Option extends Widget
    constructor:(@id,@current)->
        super
        echo "new Option:#{@id}, current:#{@current}"
        @opt_text = []
        @opt_div = []
        @opt_text_li = []
        @opt_text_span = []
        @Animation_End = false
        @element.style.position = "absolute"
        switch @id
            when "left-up"
                @current_up = true
                @current_left = true
                @element.style.left = 0
                @element.style.top = 0
            when "left-down"
                @current_up = false
                @current_left = true
                @element.style.left = 0
                @element.style.bottom= 0
            when "right-up"
                @current_up = true
                @current_left = false
                @element.style.right = 0
                @element.style.top = 0
            when "right-down"
                @current_up = false
                @current_left = false
                @element.style.right = 0
                @element.style.bottom = 0

    insert:(opt)->
        @opt_text.push(opt)

    option_build:->
        if @current_up
            @current_div_build()
            @opt_choose_div_build()
        else
            @opt_choose_div_build()
            @current_div_build()
        jQuery(@element).hover(@mouseenter,@mouseleave)

    mouseenter : =>
        echo "mouseenter"
        @current_img.style.backgroundPosition = @bg_pos_hover
        for opt,i in @opt_text
            if opt is @current then @opt_text_span[i].style.color = "#00bbfe"
            else @opt_text_span[i].style.color = "#afafaf"
        @opt_choose.style.display = "block"
        @animation_show(@opt_choose,@current_up)

    animation_show:(el,current_up)->
        @Animation_End = false
        t_show = 80
        YStartTop = 20
        YEndTop = 50
        YStartBottom = YStartTop
        YEndTopBottom = YEndTop
        el.style.opacity = "0.0"
        if current_up
            el.style.top = YStartTop
            jQuery(el).animate(
                {opacity: '1.0';top:YEndTop;},
                t_show,
                "linear",=>
                    echo "Animation End"
                    @Animation_End = true
            )
        else
            el.style.bottom = YStartBottom
            jQuery(el).animate(
                {opacity: '1.0';bottom:YEndTopBottom;},
                t_show,
                "linear",=>
                    echo "Animation End"
                    @Animation_End = true
            )

    mouseleave : =>
        echo "mouseleave"
        @current_img.style.backgroundPosition = @bg_pos_normal
        @opt_choose.style.display = "none"

    current_div_build :->
        @current_div = create_element("div","current_div",@element)
        if @current_left
            @current_img = create_element("div","current_img",@current_div)
            @current_text = create_element("div","current_text",@current_div)
            @current_div.style.webkitBoxPack = "start"
        else
            @current_text = create_element("div","current_text",@current_div)
            @current_img = create_element("div","current_img",@current_div)
            @current_div.style.webkitBoxPack = "end"
        @current_text.textContent = @current
        Delta=(n)->
            return "#{n * 102}px"
        Hover_X = 0
        Hover_Y = 2
        left = 60
        top = 0
        bottom = 0
        switch @id
            when "left-up"
                @bg_pos_normal = "#{Delta(-1)} #{Delta(-1)}"
                @bg_pos_hover = "#{Delta(-1 + Hover_X)} #{Delta(-1 + Hover_Y)}"
                @current_text.style.left = left
                @current_text.style.top = top
            when "left-down"
                @bg_pos_normal = "#{Delta(-1)} #{Delta(0)}"
                @bg_pos_hover = "#{Delta(-1 + Hover_X)} #{Delta(0 + Hover_Y)}"
                @current_text.style.left = left
                @current_text.style.bottom = bottom
            when "right-up"
                @bg_pos_normal = "#{Delta(0)} #{Delta(-1)}"
                @bg_pos_hover = "#{Delta(0 + Hover_X)} #{Delta(-1 + Hover_Y)}"
                @current_text.style.right = left
                @current_text.style.top = top
            when "right-down"
                @bg_pos_normal = "#{Delta(0)} #{Delta(0)}"
                @bg_pos_hover = "#{Delta(0 + Hover_X)} #{Delta(0 + Hover_Y)}"
                @current_text.style.right = left
                @current_text.style.bottom = bottom
        @current_img.style.backgroundPosition = @bg_pos_normal
        if !@current_left
            @current_text.style.textAlign = "right"
        else
            @current_text.style.textAlign = "left"

    opt_choose_div_build :->
        @opt_choose = create_element("ul","opt_choose",@element)
        left = 50
        if @current_left
            @opt_choose.style.left = left
        else
            echo "right"
            @opt_choose.style.right = left
        if !@current_up then @opt_text.reverse()
        for opt,i in @opt_text
            @opt_text_li[i] = create_element("li","opt_text_li",@opt_choose)
            @opt_text_span[i] = create_element("span","opt_text_span",@opt_text_li[i])
            @opt_text_span[i].textContent = opt
            if !@current_left
                @opt_text_span[i].style.float = "right"
                @opt_text_span[i].style.textAlign = "right"
            else
                @opt_text_span[i].style.float = "left"
                @opt_text_span[i].style.textAlign = "left"

            that = @
            @opt_text_span[i].addEventListener("click",(e)->
                e.stopPropagation()
                that.current = this.textContent
                that.opt_choose.style.display = "none"
                that.current_text.textContent = that.current
                that.setZone(that.id,that.current)
            )
            jQuery(@opt_text_span[i]).hover((e)->
                if !that.Animation_End then this.style.backgroundColor = null
                else this.style.backgroundColor = "rgb(0,0,0)"
            ,(e)->
                this.style.backgroundColor = null
            )

        @opt_choose.style.display = "none"


    setZone:(id,current)->
        key = id
        value = cfgValue[i] for text,i in option_text when current is text
        setZoneConfig(key,value)
