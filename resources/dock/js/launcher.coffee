launcher_mouseout_id = null
class Launcher extends AppItem
    constructor: (@id, @icon, @core, @actions)->
        super
        @app_id = @id
        @update_scale()

        @set_tooltip(DCore.DEntry.get_name(@core))

    try_swap_clientgroup: ->
        @destroy_tooltip()
        group = Widget.look_up("le_"+@id)
        if group?
            swap_element(@element, group.element)
            group.destroy()

    do_click: (e)=>
        @destroy_tooltip()
        @flash()
        @_do_launch([])

    do_rightclick: =>
        Preview_close_now()

        @menu?.destroy()
        @menu = null
        @menu = new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem("10", _("_Run"))
        ).addSeparator()

        for i in [0...@actions.length]
            @menu.append(new MenuItem("#{i}", "_#{@actions[i].name}"))

        if @actions.length > 0
            @menu.addSeparator()

        @menu.append(new MenuItem('20', _("_Undock")))
        xy = get_page_xy(@element)
        # echo "#{xy.x}(+#{@element.clientWidth / 2})x#{xy.y}(+#{OFFSET_DOWN})"
        @menu.addListener(@on_itemselected).showMenu(
            xy.x + @element.clientWidth / 2,
            xy.y + OFFSET_DOWN,
            DEEPIN_MENU_CORNER_DIRECTION.DOWN
        )

    on_itemselected: (id, checked)=>
        super

        id = parseInt(id)
        # echo "id: #{id}"
        action = @actions[id]
        if action?
            # echo "#{action.name}, #{action.exec}"
            DCore.Dock.launch_from_commandline(@app_id, action.exec)
            return

        switch id
            when 10
                @destroy_tooltip()
                @_do_launch([])
            when 20 then DCore.Dock.request_undock(@id)

    destroy_with_animation: ->
        @img.classList.remove("ReflectImg")
        calc_app_item_size()
        @rotate()
        setTimeout(=>
            @destroy()
        ,500)

    do_mouseover: (e)=>
        super
        Preview_close_now()
        DCore.Dock.require_all_region()
        clearTimeout(hide_id)

    do_mouseout: (e)=>
        super
        if Preview_container.is_showing
            __clear_timeout()
            clearTimeout(tooltip_hide_id)
            DCore.Dock.require_all_region()
            launcher_mouseout_id = setTimeout(->
                calc_app_item_size()
                # update_dock_region()
            , 1000)
        else
            calc_app_item_size()
            # update_dock_region()
            setTimeout(->
                DCore.Dock.update_hide_mode()
            , 500)
