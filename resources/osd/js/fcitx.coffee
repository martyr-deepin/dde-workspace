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
class Fcitx
    FCITX = "org.fcitx.Fcitx-0"
    FCITX_STATUS =
        name: FCITX
        path: "/StatusNotifierItem"
        interface: "org.kde.StatusNotifierItem"

    FCITX_INPUTMETHOD =
        name: FCITX
        path: "/inputmethod"
        interface: "org.fcitx.Fcitx.InputMethod"

    FCITX_KEYBOARD =
        name: FCITX
        path: "/keyboard"
        interface: "org.fcitx.Fcitx.Keyboard"

    constructor: ->
        echo "New Fcitx"
        @IMList = []
        @IMTrueList = []
        @Layouts = []

        @getDBus()

    getDBus:->
        try
            @DBusStatus = DCore.DBus.session_object(
                FCITX_STATUS.name,
                FCITX_STATUS.path,
                FCITX_STATUS.interface
            )
        catch e
            echo "DBusStatus :#{FCITX_STATUS.interface} ---#{e}---"

        try
            @DBusIM = DCore.DBus.session_object(
                FCITX_INPUTMETHOD.name,
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
                FCITX_KEYBOARD.name,
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
        if @CurrentState == 0 then @IMState = "IM_HIDE"
        else if @PrevState != @CurrentState and @PrevIM isnt @CurrentIM and @CurrentState != 0 then @IMState = "IM_CHANGED"
        else if @CurrentState != 0  then @IMState = "IM_SHOW"
        else @IMState = "IM_OTHER"
        return @IMState

    setCurrentIM: (im)->
        @DBusIM.SetCurrentIM_sync(im)


    getLayouts: ->
        @Layouts = @DBusLayout.GetLayouts_sync()

    setLayoutForIM: (im,layout,variant)->
        @DBusLayout.SetLayoutForIM_sync(im,layout.variant)

    setDefaultLayout: (layout,variant)->
        @DBusLayout.SetDefaultLayout_sync(layout.variant)


    fcitxSignalsConnect:(cbIMState) ->
        @DBusStatus.connect("NewIcon",cbIMState)
        #@DBusStatus.connect("NewToolTip",@fcitxSwitch)

class FcitxOSD extends Widget
    constructor:(@id)->
        super
        echo "New FcitxOSD :#{@id}"
        _b.appendChild(@element)

        @fcitx = new Fcitx()
        @fcitx.fcitxSignalsConnect(@cbIMState)

    hide:->
        @element.style.display = "none"

    show:->
        @element.style.display = "-webkit-box"

    imListBackgroundChange: ->
        if not @IMListul?
            @IMli = []
            @IMli_span = []
            @IMListul = create_element("ul","IMListul",@element)
            for im,i in @fcitx.IMTrueList
                @IMli[i] = create_element("li","IMli",@IMListul)
                @IMli_span[i] = create_element("span","IMli_span",@IMli[i])
                @IMli_span[i].textContent = im[0]

        @fcitx.getIMState()
        @currentIMIndex = @fcitx.CurrentState - 1
        @currentIMIndex = @fcitx.PrevState if @currentIMIndex == -1

        for li,i in @IMli
            if i == @currentIMIndex
                li.style.border = "rgba(255,255,255,0.5) 2px solid"
                li.style.backgroundColor = "rgb(0,0,0)"
            else
                li.style.border = "rgba(255,255,255,0.0) 2px solid"
                li.style.backgroundColor = null

    cbIMState: =>
        echo "cbIMState"
        @IMState = @fcitx.getIMState()
        switch @IMState
            when "IM_HIDE" then @IMHide()
            when "IM_SHOW" then @IMShow()
            when "IM_CHANGED" then @IMChanged()
            when "IM_OTHER" then @IMOther()

    IMHide: ->
        echo "IMHide"
        @hide()

    IMShow: ->
        echo "IMShow"

    IMChanged: ->
        echo "IMChanged"
        #setBodySize(160,120)
        clearTimeout(timeout_osdHide)
        osdShow()
        @show()
        @imListBackgroundChange()
        timeout_osdHide = setTimeout(osdHide,TIME_HIDE)

    IMOther: ->
        echo "IMOther"

# fcitxOSD = new FcitxOSD("FcitxOSD")
