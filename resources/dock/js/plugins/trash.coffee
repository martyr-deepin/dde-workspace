class Trash extends PostfixedItem
    constructor:(@id, icon, title)->
        super
        @set_tooltip(title)
        @w_id = 0
        @is_opened = false
        @entry = DCore.DEntry.get_trash_entry()
        @emptyIcon = Trash.get_icon(0)
        @fullIcon = Trash.get_icon(1)
        @change_icon(icon)
        @imgHover.style.display = 'none'
        @imgContainer.addEventListener("drop", @on_drop)
        @isEmpty = false
        @update()
        DCore.signal_connect("trash_count_changed", (info)=>
            @update(info.value)
        )

    on_rightclick: (e)=>
        super
        e.preventDefault()
        e.stopPropagation()
        menu = new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem(1, _("_Clean up")).setActive(DCore.DEntry.get_trash_count() != 0)
        )
        if @is_opened
            menu.append(new MenuItem(2, _("_Close")))
        xy = get_page_xy(@element)
        # echo menu
        menu.addListener(@on_itemselected).showMenu(
            xy.x + (@element.clientWidth / 2),
            xy.y + OFFSET_DOWN,
            DEEPIN_MENU_CORNER_DIRECTION.DOWN
        )

    on_itemselected: (id)=>
        # super
        id = parseInt(id)
        switch id
            when 1
                d = get_dbus("session",
                        name:"org.gnome.Nautilus",
                        path:"/org/gnome/Nautilus",
                        interface:"org.gnome.Nautilus.FileOperations",
                        "EmptyTrash"
                )
                d.EmptyTrash()
                @update()
            when 2
                clientManager?.CloseWindow(@w_id)

    on_click: (e)=>
        e.stopPropagation()
        super
        if  @is_opened
            @core.Activate(0,0)
            return
        @openingIndicator.style.display = 'inline'
        @openingIndicator.style.webkitAnimationName = 'Breath'
        if !DCore.DEntry.launch(@entry, [])
            confirm(_("Can not open this file."), _("Warning"))

    on_drop: (evt)=>
        evt.stopPropagation()
        evt.preventDefault()
        if dnd_is_file(evt) or dnd_is_desktop(evt)
            tmp_list = []
            for file in evt.dataTransfer.files
                e = DCore.DEntry.create_by_path(decodeURI(file.path).replace(/^file:\/\//i, ""))
                if not e? then continue
                tmp_list.push(e)
            if tmp_list.length > 0 then DCore.DEntry.trash(tmp_list)

    on_dragenter : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        @oldEffect = evt.dataTransfer.dropEffect
        evt.dataTransfer.dropEffect = "move"

    on_dragover : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()

    on_dragleave : (evt) =>
        evt.stopPropagation()
        evt.preventDefault()
        evt.dataTransfer.dropEffect = @oldEffect

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
