launcher_mouseout_id = null
class Launcher extends AppItem
    constructor: (@id, @icon, @core, @actions)->
        super
        @app_id = @id
        @update_scale()

        @set_tooltip(DCore.DEntry.get_name(@core))

        @build_menu()

    try_swap_clientgroup: ->
        group = Widget.look_up("le_"+@id)
        if group?
            swap_element(@element, group.element)
            group.destroy()

    do_click: (e)=>
        @tooltip?.hide()
        @tooltip = null
        @flash()
        @_do_launch []

    on_itemselected: (id)=>
        super
        id = parseInt(id)

        action = @actions[id - 1]
        if action?
            DCore.Dock.launch_from_commandline(@app_id, action.exec)
            return

        switch id
            when 10
                @tooltip?.hide()
                @tooltip = null
                @_do_launch []
            when 20 then DCore.Dock.request_undock(@id)

    build_menu: (e)=>
        e.stopPropagation()
        []

    do_rightclick: (e) =>
        super
        menu = create_menu(MENU_TYPE_NORMAL, new MenuItem("10", _("_Run")))
        menu.addSeparator()

        for i in [0...@actions.length]
            menu.append(new MenuItem("#{i}", @actions[i].name))

        if @actions.length > 0
            menu.addSeparator()

        menu.append(new MenuItem('20', _("_Undock")))

        xy = get_page_xy(@element)
        menu.listenItemSelected(@on_itemselected)
        menu.showDockMenu(xy.x + @element.clientWidth / 2, xy.y, 'down')

    destroy_with_animation: ->
        @img.classList.remove("ReflectImg")
        t = @element.parentElement.removeChild(@element)
        document.body.appendChild(t)
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
