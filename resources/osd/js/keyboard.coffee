class Keyboard
    #Keyboard DBus
    KEYBOARD =
        name: "com.deepin.daemon.InputDevices"
        path: "/com/deepin/daemon/InputDevice/Keyboard"
        interface: "com.deepin.daemon.InputDevice.Keyboard"

    constructor:->
        echo "New Keyboard"
        @UserLayoutList = []

    getDBus: ->
        try
            @DBusKeyboard = get_dbus("session",KEYBOARD,"UserLayoutList")
            @UserLayoutList = @DBusKeyboard.UserLayoutList
        catch e
            echo " DBusKeyboard :#{KEYBOARD} ---#{e}---"

    getCurrentLayout: ->
        return @DBusKeyboard?.CurrentLayout

    setCurrentLayout: (layout)->
        @DBusKeyboard?.CurrentLayout = layout


keyboard = null
keyboardList = null

SwitchLayout = (keydown)->
    if keydown then return
    setFocus(false)
    echo "SwitchLayout"

    keyboard = new Keyboard() if not keyboard?
    keyboard.getDBus()
    if keyboard.UserLayoutList.length < 2 then return

    if not keyboardList?
        keyboardList = new ListChoose("KeyboardList")
        keyboardList.setPosition(_b,0,0,"absolute")
        keyboardList.setSize("100%","100%")
        keyboardList.ListAllBuild(keyboard.UserLayoutList,keyboard.getCurrentLayout())

    current = keyboardList.ChooseIndex()
    keyboard.setCurrentLayout(current)

DBusMediaKey.connect("SwitchLayout",SwitchLayout) if DBusMediaKey?
