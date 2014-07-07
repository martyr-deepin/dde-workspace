#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 yilang
#
#Author:      LongWei <yilang2007lw@gmail.com>
#                     <snyh@snyh.org>
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

class PowerMenu extends Widget
    
    constructor: (parent_el) ->
        super
        @power_dict = {}
        @power_title = {
            shutdown:_("Shut down")
            restart:_("Restart")
            suspend:_("Suspend")
        }
        
        @parent = parent_el
        @img_before = "images/powermenu/"
        if not @parent? then @parent = document.body
        @parent.appendChild(@element)

        @clear_shutdown_from_lock()
        
        @powercls = new Power()
        @powercls.power_get_inhibit()
        
    suspend_cb : =>
        @powercls.power_force_sys("suspend")

    restart_cb : =>
        @powercls.power_force_sys("restart")

    shutdown_cb : =>
        @powercls.power_force_sys("shutdown")

    get_power_dict : ->
        @power_dict["shutdown"] = @shutdown_cb
        @power_dict["restart"] = @restart_cb
        @power_dict["suspend"] = @suspend_cb

    menuChoose_click_cb : (id, title) =>
        if is_greeter
            @power_dict[id]()
        else
            if id is "suspend"
                @power_dict["suspend"]()
            else
                @username = accounts.get_default_username()
                @userid = accounts.get_user_id(@username)
                @is_need_pwd = accounts?.is_need_pwd(@userid)
                if @is_need_pwd then @confirm_shutdown_show(id)
                else @power_dict[id]()

    new_power_menu:->
        echo "new_power_menu"
        @get_power_dict()
        @ComboBox = new ComboBox("power", @menuChoose_click_cb)
        for key, title of @power_title
            img_normal = @img_before + "#{key}_normal.png"
            img_hover = @img_before + "#{key}_hover.png"
            img_click = @img_before + "#{key}_press.png"
            can_exe =  @powercls.power_can(key)
            message_text = @powercls.inhibit_msg(key)
            @ComboBox.insert(key, title, img_normal,img_hover,img_click,!can_exe,message_text)
        
        @ComboBox.frame_build()
        @element.appendChild(@ComboBox.element)
        @ComboBox.current_img.src = @img_before + "powermenu.png"

    keydown_listener:(e)->
        @ComboBox.menu.keydown(e)

    confirm_shutdown_show:(powervalue)=>
        power = {"lock":true,"value":powervalue}
        localStorage.setObject("shutdown_from_lock",power)

        power_title = @power_title[powervalue]
        value = _("Enter your password to %1").args(power_title)
        localStorage.setItem("password_value_shutdown",value)
        
        password_error = (msg) =>
            $(".password").style.color = "#F4AF53"
            $(".password").style.fontSize = "1.2em"
            $(".password").style.paddingBottom = "0.4em"
            $(".password").style.letterSpacing = "0px"
            $(".password").type = "text"
            password_error_msg = msg
            $(".password").value = password_error_msg
            $(".password").blur()
            $(".loginbutton").disable = true
        
        password_error(value)
        $(".loginbutton").src = "images/userinfo/#{powervalue}_normal.png"
        $(".password").focus()
        
        document.body.addEventListener("click",(e)=>
            e.stopPropagation()
            @confirm_shutdown_hide()
        )
        

    confirm_shutdown_hide:=>
        if @check_is_shutdown_from_lock()
            power = @clear_shutdown_from_lock()
        else
            return
        
        input_password_again = =>
            $(".password").style.color = "rgba(255,255,255,0.5)"
            $(".password").style.fontSize = "2.0em"
            $(".password").style.paddingBottom = "0.2em"
            $(".password").style.letterSpacing = "5px"
            $(".password").type = "password"
            $(".password").focus()
            $(".loginbutton").disable = false
            $(".password").value = null

        input_password_again()
        t_userinfo_show_hide = 600
        jQuery(".loginbutton").animate(
            {opacity:'0.0';},
            t_userinfo_show_hide,
            "linear",=>
                $(".loginbutton").src = "images/userinfo/lock_normal.png"
                jQuery(".loginbutton").animate(
                    {opacity:'1.0';},
                    t_userinfo_show_hide
                )
        )

    check_is_shutdown_from_lock : ->
        power_flag = false
        if (power = localStorage.getObject("shutdown_from_lock"))?
            if power.lock is true
                power_flag = true
        return power_flag

    clear_shutdown_from_lock : ->
        if (power = localStorage.getObject("shutdown_from_lock"))?
            power.lock = false
            localStorage.setObject("shutdown_from_lock",power)
        else
            power = {"lock":false,"value":null}
            localStorage.setObject("shutdown_from_lock",power)
        return power
             
    set_shutdown_from_lock : (powervalue) ->
        if (power = localStorage.getObject("shutdown_from_lock"))?
            power.lock = true
            power.value = powervalue
            localStorage.setObject("shutdown_from_lock",power)
        return
    
    auth_succeed_excute: ->
        echo "PowerMenu auth_succeed_excute"
        if @check_is_shutdown_from_lock()
            power = @clear_shutdown_from_lock()
            if not power.value? then return
            if @powercls.power_can(power.value)
                power_force(power.value)


