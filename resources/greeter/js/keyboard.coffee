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
            @CurrentLayout = @getCurrentLayout()
            @getAllLayoutList()
        catch e
            echo " DBusKeyboard :#{KEYBOARD} ---#{e}---"

    updateUserLayoutList:->
        @UserLayoutList_en = []
        @UserLayoutList_en = @DBusKeyboard?.UserLayoutList
        @UserLayoutList = []
        for l in @UserLayoutList_en
           @UserLayoutList.push(@AlllayoutList[l])
        return @UserLayoutList

    getAllLayoutList: ->
        @AlllayoutList = @DBusKeyboard.LayoutList_sync()

    getCurrentLayout: ->
        @CurrentLayout_en = @DBusKeyboard?.CurrentLayout
        @CurrentLayout = @AlllayoutList[@CurrentLayout_en]
        echo "@CurrentLayout : #{@CurrentLayout} ; @CurrentLayout_en:#{@CurrentLayout_en}"
        return @CurrentLayout

    getCurrentLayoutIndex: ->
        return j for each ,j in @UserLayoutList when @getCurrentLayout() is each

    setCurrentLayout: (layout)->
        @CurrentLayout = layout
        @CurrentLayout_en = @UserLayoutList_en[i] for l,i in @UserLayoutList when l is @CurrentLayout
        @DBusKeyboard?.CurrentLayout = @CurrentLayout_en
        echo "setCurrentLayout:#{@CurrentLayout_en}:#{layout}"

