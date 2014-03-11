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

class Fcitx extends Widget
    FCITX = "org.fcitx.Fcitx-0"
    FCITX_STATUS =
        obj: FCITX
        path: "/StatusNotifierItem"
        interface: "org.kde.StatusNotifierItem"

    FCITX_INPUTMETHOD =
        obj: FCITX
        path: "/inputmethod"
        interface: "org.fcitx.Fcitx.InputMethod"

    FCITX_KEYBOARD =
        obj: FCITX
        path: "/keyboard"
        interface: "org.fcitx.Fcitx.Keyboard"

    IM_HIDE = 0
    IM_SHOW = 1
    IM_CHANGED = 2
    IM_OTHER = 3
    
    constructor:(@id)->
        super
        echo "New Fcitx :#{@id}"
        @IMList = []
        @IMTrueList = []

        @Layouts = []

        @valueEach = []
        
        _b.appendChild(@element)
        @getDBus()
   
    hide:->
        @element.style.display = "none"
    
    set_bg:(imgName)->
        @element.style.backgroundImage = "url(img/#{imgName}.png)"
  
    
    getDBus:->
        try
            @DBusStatus = DCore.DBus.session_object(
                FCITX_STATUS.obj,
                FCITX_STATUS.path,
                FCITX_STATUS.interface
            )
        catch e
            echo "DBusStatus :#{FCITX_STATUS.interface} ---#{e}---"

        try
            @DBusIM = DCore.DBus.session_object(
                FCITX_INPUTMETHOD.obj,
                FCITX_INPUTMETHOD.path,
                FCITX_INPUTMETHOD.interface
            )
            @IMList = @DBusIM.IMList
            @IMTrueList.push(im) for im in @IMList when im[3]
            echo @IMTrueList
            @CurrentIM = @DBusIM.GetCurrentIM_sync()
            @CurrentState = @DBusIM.GetCurrentState_sync()
        catch e
            echo "DBusIM :#{FCITX_INPUTMETHOD.interface} ---#{e}---"

        try
            @DBusLayout = DCore.DBus.session_object(
                FCITX_KEYBOARD.obj,
                FCITX_KEYBOARD.path,
                FCITX_KEYBOARD.interface
            )
            @Layouts = @DBusLayout.GetLayouts_sync()
        catch e
            echo "DBusLayout :#{FCITX_KEYBOARD.interface} ---#{e}---"

        
    getCurrentIMState: ->
        @PrevIM = @CurrentIM
        @CurrentIM = @DBusIM.GetCurrentIM_sync()
        @PrevState = @CurrentState
        @CurrentState = @DBusIM.GetCurrentState_sync()
        echo "@CurrentIM:#{@CurrentIM},@CurrentState:#{@CurrentState}"
   

    getIMState: ->
        @getCurrentIMState()
        if @CurrentState == 0 then return "IM_HIDE"
        else if @PrevState != @CurrentState and @PrevIM isnt @CurrentIM and @CurrentState != 0 then return "IM_CHANGED"
        else if @CurrentState != 0  then return "IM_SHOW"
        else return "IM_OTHER"
 
    setCurrentIM: (im)->
        @DBusIM.SetCurrentIM_sync(im)


    getLayouts: ->
        @Layouts = @DBusLayout.GetLayouts_sync()

    setLayoutForIM: (im,layout,variant)->
        @DBusLayout.SetLayoutForIM_sync(im,layout.variant)
    
    setDefaultLayout: (layout,variant)->
        @DBusLayout.SetDefaultLayout_sync(layout.variant)


    fcitxSignalsConnect: ->
        @DBusStatus.connect("NewIcon",@fcitxSwitch)
        #@DBusStatus.connect("NewToolTip",@fcitxSwitch)
    
    
    fcitxSwitch: =>
        echo "fcitxSwitch"
        @state = @getIMState()
        switch @state
            when "IM_HIDE" then @IMHide()
            when "IM_SHOW" then @IMShow()
            when "IM_CHANGED" then @IMChanged()
            when "IM_OTHER" then @IMOther()

    IMHide: ->
        echo "IMHide"

    IMShow: ->
        echo "IMShow"

    IMChanged: ->
        echo "IMChanged"

    IMOther: ->
        echo "IMOther"



fcitx = new Fcitx("fcitx")
fcitx.fcitxSignalsConnect()
