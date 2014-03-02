#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2011 ~ 2013 yilang
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

key_NameValue = [
    {Name:"CapsLock_on",Value:"Caps_Lock"},
    {Name:"CapsLock_off",Value:"caps_lock-Caps_Lock"},
    {Name:"NumLock_on",Value:"Num_Lock"},
    {Name:"NumLock_off",Value:"num_lock-Num_Lock"},
    {Name:"Light_Up",Value:"XF86MonBrightnessUp"},
    {Name:"Light_Down",Value:"XF86MonBrightnessDown"},
    {Name:"Voice_Up",Value:"XF86AudioRaiseVolume"},
    {Name:"Voice_Down",Value:"XF86AudioLowerVolume"},
    {Name:"Voice_Mute",Value:"XF86AudioMute"},
    {Name:"DisplayMode",Value:"XF86Display"}
    {Name:"Wifi_On",Value:"XF86WifiOn"},
    {Name:"Wifi_Off",Value:"XF86WifiOff"},
    {Name:"InputSwitch",Value:"mod4-i"},
    {Name:"KeyLayout",Value:"mod4-k"},
]

#dconf-tools  
#org/gonome/settings-daemon/plugins/media-keys/active false
#com/deepin/dde/key-binding/mediakey
#dbus-monitor "sender='com.deepin.daemon.MediaKey', type='signal'"           
echo key_NameValue

set_el_bg =(el,src)->
    el.style.backgroundImage = "url(#{src})"


MEDIAKEY = "com.deepin.daemon.MediaKey"
TIME_HIDE = 4000