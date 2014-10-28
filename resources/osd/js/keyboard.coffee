class Keyboard
    #Keyboard DBus
    KEYBOARD =
        name: "com.deepin.daemon.InputDevices"
        path: "/com/deepin/daemon/InputDevice/Keyboard"
        interface: "com.deepin.daemon.InputDevice.Keyboard"

    constructor:->
        echo "New Keyboard"
        @AlllayoutList = []
        @UserLayoutList_en = []
        @UserLayoutList = []

        @CurrentLayout_en = null
        @CurrentLayout = null
        @getDBus()

    getDBus: ->
        try
            @DBusKeyboard = DCore.DBus.session_object(
                KEYBOARD.name,
                KEYBOARD.path,
                KEYBOARD.interface
            )
            @getAllLayoutList()
            @CurrentLayout = @getCurrentLayout()
            @updateUserLayoutList()
        catch e
            echo " DBusKeyboard :#{KEYBOARD} ---#{e}---"

    updateUserLayoutList:->
        @UserLayoutList_en = []
        @UserLayoutList_en = @DBusKeyboard?.UserLayoutList
        @UserLayoutList = []
        for l in @UserLayoutList_en
           @UserLayoutList.push(@AlllayoutList[l])
        echo "UserLayoutList.length: #{@UserLayoutList.length}"
        return @UserLayoutList

    getAllLayoutList: ->
        @AlllayoutList = @DBusKeyboard.LayoutList_sync()

    getCurrentLayout: ->
        @CurrentLayout_en = @DBusKeyboard?.CurrentLayout
        @CurrentLayout = @AlllayoutList[@CurrentLayout_en]
        echo "@CurrentLayout : #{@CurrentLayout} ; @CurrentLayout_en:#{@CurrentLayout_en}"
        return @CurrentLayout

    setCurrentLayout: (layout)->
        @CurrentLayout = layout
        @CurrentLayout_en = @UserLayoutList_en[i] for l,i in @UserLayoutList when l is @CurrentLayout
        @DBusKeyboard?.CurrentLayout = @CurrentLayout_en
        echo "setCurrentLayout:#{@CurrentLayout_en}:#{layout}"


keyboard = null
keyboardList = null

osd.SwitchLayout = (keydown)->
    if !keydown then return if mode is "dbus"

    keyboard = new Keyboard() if not keyboard?
    len = keyboard.UserLayoutList.length
    if len < 2
        osdHide()
        return

    osdShow()
    if not keyboardList?
        keyboardList = new ListChoose("KeyboardList")
        keyboardList.setParent(_b)
        keyboardList.ListAllBuild(keyboard.UserLayoutList,keyboard.getCurrentLayout())
        keyboardList.setSize(180,210)
    else
        keyboardList?.chooseOption()
        keyboardList?.scrollOption()
    keyboardList.setWinSize()
    clearTimeout(timeout_osdHide)
    timeout_osdHide = setTimeout(=>
        keyboard.setCurrentLayout(keyboardList.current)
        osdHide()
    ,TIME_HIDE)
