class Keyboard
    #Keyboard DBus
    KEYBOARD =
        name: "com.deepin.daemon.InputDevices"
        path: "/com/deepin/daemon/InputDevice/Keyboard"
        interface: "com.deepin.daemon.InputDevice.Keyboard"

    constructor:->
        echo "New Keyboard"
        @UserLayoutList = []

        @CurrentLayout = null
        @getDBus()
        @setKeyupListener(KEYCODE.WIN)
    
    setKeyupListener:(KeyCode)->
        @isFromList = false
        _b.addEventListener("keyup",(e)=>
            if e.which == KeyCode and @isFromList is true
                @isFromList = false
                @setCurrentLayout(@CurrentLayout)
        )
    

    getDBus: ->
        try
            @DBusKeyboard = get_dbus("session",KEYBOARD,"UserLayoutList")
            @CurrentLayout = @getCurrentLayout()
        catch e
            echo " DBusKeyboard :#{KEYBOARD} ---#{e}---"

    updateUserLayoutList:->
        @UserLayoutList = @DBusKeyboard?.UserLayoutList
        return @UserLayoutList


    getCurrentLayout: ->
        return @DBusKeyboard?.CurrentLayout

    getCurrentLayoutIndex: ->
        return j for each ,j in @UserLayoutList when @getCurrentLayout() is each

    setCurrentLayout: (layout)->
        echo "setCurrentLayout:#{layout}"
        @CurrentLayout = layout
        @DBusKeyboard?.CurrentLayout = layout


keyboard = null
keyboardList = null

SwitchLayout = (keydown)->
    if keydown then return
    setFocus(false)
    echo "SwitchLayout"
    
    keyboard = new Keyboard() if not keyboard?
    keyboard.updateUserLayoutList()
    echo "UserLayoutList.length: #{keyboard.UserLayoutList.length}"
    if keyboard.UserLayoutList.length < 2 then return
    
    if not keyboardList?
        keyboardList = new ListChoose("KeyboardList")
        keyboardList.setParent(_b)
        #keyboardList.setPosition(0,0,"absolute")
        keyboardList.setSize("100%","100%")
        keyboardList.ListAllBuild(keyboard.UserLayoutList,keyboard.getCurrentLayout())

    current = keyboardList.chooseOption()
    keyboard.isFromList = true
    keyboard.CurrentLayout = current

DBusMediaKey.connect("SwitchLayout",SwitchLayout) if DBusMediaKey?
