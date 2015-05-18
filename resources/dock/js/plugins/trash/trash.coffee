dialog = null

uninstallSuccessHandler=(id)->

uninstallFailedHandler=(id, reason)->

class Trash extends PostfixedItem
    constructor:(@id, icon, @title)->
        super
        # @imgContainer.draggable = true
        @set_tooltip(@title)
        @w_id = 0
        @is_opened = false
        @entry = DCore.DEntry.get_trash_entry()
        @emptyIcon = Trash.get_icon(0)
        @fullIcon = Trash.get_icon(1)
        @emptyOpenIcon = DCore.get_theme_icon(EMPTY_TRASH_OPENED_ICON, 48) || Trash.get_icon(0)
        @fullOpenIcon = DCore.get_theme_icon(FULL_TRASH_OPENED_ICON, 48) || Trash.get_icon(1)
        @change_icon(icon)
        @imgHover.style.display = 'none'
        @isEmpty = false
        @update()
        DCore.signal_connect("trash_count_changed", (info)=>
            @update(info.value)
        )

    on_mouseover:(e)=>
        super
        @set_tooltip(@title)
        @tooltip.show()

    on_rightclick: (e)=>
        super
        e.preventDefault()
        e.stopPropagation()
        menu = new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem(1, _("_Empty")).setActive(DCore.DEntry.get_trash_count() != 0)
        )
        menu.unregisterHook(handleMenuUnregister)
        if @is_opened
            menu.append(new MenuItem(2, _("_Close")))
        screenOffset =
            x: e.screenX - e.pageX
            y: e.screenY - e.pageY
        xy = get_page_xy(@element)
        # echo menu
        menu.addListener(@on_itemselected).showMenu(
            xy.x + (@element.clientWidth / 2) + screenOffset.x,
            xy.y + screenOffset.y,
            DEEPIN_MENU_CORNER_DIRECTION.DOWN
        )

    on_itemselected: (id)=>
        # super
        id = parseInt(id)
        switch id
            when 1
                try
                    d = get_dbus("session",
                            name:"org.gnome.Nautilus",
                            path:"/org/gnome/Nautilus",
                            interface:"org.gnome.Nautilus.FileOperations",
                            "EmptyTrash"
                    )
                    d.EmptyTrash()
                catch e
                    console.log(e)
                @update()
            when 2
                clientManager?.CloseWindow(@w_id)

    on_mouseup: (e)=>
        e.stopPropagation()
        super
        if e.button != 0
            return
        if @is_opened
            @core?.Activate(0,0)
            return
        @is_opened = true
        @openingIndicator.style.display = 'inline'
        @openingIndicator.style.webkitAnimationName = 'Breath'
        if !DCore.DEntry.launch(@entry, [])
            confirm(_("Can not open this file."), _("Warning"))

    uninstallHandler: (id, action)=>
        switch action
            when "2"
                console.log 'start uninstall'
                if @data.icon.indexOf("data:image") != -1
                    icon = @data.icon
                else
                    icon = DCore.get_theme_icon(@data.icon, 48)
                icon = DCore.backup_app_icon(icon)
                console.log("set icon: #{icon} to notify icon")
                uninstaller = new Uninstaller(@data.id, "Deepin Dock", icon, uninstallSuccessHandler, uninstallFailedHandler)
                setTimeout(=>
                    uninstaller.uninstall()
                , 100)

        dialog.dis_connect("ActionInvoked", @uninstallHandler)

        dialog = null

    on_drop: (evt)=>
        evt.stopPropagation()
        evt.preventDefault()
        dt = evt.dataTransfer
        if (data = dt.getData("uninstall")) != ""
            console.log(data)
            @data = JSON.parse(data)
            console.log("TODO: uninstall #{data.id}")
            dialog = get_dbus('session', "com.deepin.dialog", "ShowUninstall")
            dialog.connect("ActionInvoked", @uninstallHandler)
            console.log(dialog.ShowUninstall)
            if @data.icon.indexOf("data:image") != -1
                icon = @data.icon
            else
                icon = DCore.get_theme_icon(@data.icon, 48)
            icon = DCore.backup_app_icon(icon)
            dialog.ShowUninstall(icon, _("Are you sure to remove") + " \"#{@data.name}\" ", _("All dependencies will be removed"), ["1", _("no"), "2", _("yes")])
        else if dnd_is_file(evt) or dnd_is_desktop(evt)
            tmp_list = []
            for file in dt.files
                e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                if not e? then continue
                tmp_list.push(e)
            if tmp_list.length > 0 then DCore.DEntry.trash(tmp_list)

        @update()

    on_dragenter : (evt) =>
        console.log("dragenter trash")
        evt.stopPropagation()
        evt.preventDefault()
        @oldEffect = evt.dataTransfer.dropEffect
        evt.dataTransfer.dropEffect = "move"
        if @isEmpty
            @change_icon(@emptyOpenIcon)
        else
            @change_icon(@fullOpenIcon)

    on_dragover : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()

    on_dragleave : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        evt.dataTransfer.dropEffect = @oldEffect
        @update()

    show_indicator: ->
        console.log("show_indicator")
        @is_opened = true
        @openIndicator.style.display = ""
        @openingIndicator.style.display = 'none'
        @openingIndicator.style.webkitAnimationName = ''

    hide_indicator:->
        @is_opened = false
        @id = 0
        @openIndicator.style.display = "none"

    set_id: (id)->
        @id = id
        @

    @get_icon: (n) ->
        if n == 0
            DCore.get_theme_icon(EMPTY_TRASH_ICON, 48)
        else
            DCore.get_theme_icon(FULL_TRASH_ICON, 48)

    update: (n=null)->
        n = DCore.DEntry.get_trash_count() if n == null
        if n == 0
            @isEmpty = true
            @change_icon(@emptyIcon)
        else
            @isEmpty = false
            @change_icon(@fullIcon)

    update_icon:->
        @emptyIcon = Trash.get_icon(0)
        @fullIcon = Trash.get_icon(1)
        @emptyOpenIcon = DCore.get_theme_icon(EMPTY_TRASH_OPENED_ICON, 48) || Trash.get_icon(0)
        @fullOpenIcon = DCore.get_theme_icon(FULL_TRASH_OPENED_ICON, 48) || Trash.get_icon(1)
        @update()
