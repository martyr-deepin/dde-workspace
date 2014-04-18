class Keyboard
    #Keyboard DBus
    KEYBOARD =
        name: "com.deepin.daemon.InputDevices"
        path: "/com/deepin/daemon/InputDevice/Keyboard"
        interface: "com.deepin.daemon.InputDevice.Keyboard"

    constructor:->
        echo "New Keyboard"
        @UserLayoutList = []
        @getDBus()
    
    getDBus: ->
        try
            @DBusKeyboard = get_dbus("session",KEYBOARD,"UserLayoutList")
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

    current = keyboardList.ChooseIndex()
    echo "6"
    #keyboard.setCurrentLayout(current)
    echo "7"

DBusMediaKey.connect("SwitchLayout",SwitchLayout) if DBusMediaKey?
