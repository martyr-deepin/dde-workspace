launcher_mouseout_id = null
class Launcher extends AppItem
    constructor: (@id, @icon, @core)->
        super
        @app_id = @id
        @update_scale()

        @set_tooltip(DCore.DEntry.get_name(@core))


    try_swap_clientgroup: ->
        group = Widget.look_up("le_"+@id)
        if group?
            swap_element(@element, group.element)
            group.destroy()

    do_click: (e)->
        @tooltip?.hide()
        @tooltip = null
        @flash()
        @_do_launch []

    do_itemselected: (e)->
        switch e.id
            when 1
                @tooltip?.hide()
                @tooltip = null
                @_do_launch []
            when 2 then DCore.Dock.request_undock(@id)
    do_buildmenu: (e)->
        Preview_close_now()
        [
            [1, _("_Run")],
            [],
            [2, _("_Undock")],
        ]
    destroy_with_animation: ->
        @img.classList.remove("ReflectImg")
        @rotate()
        setTimeout(=>
            @destroy()
        ,500)

    do_mouseover: (e)->
        Preview_close_now()
        clearTimeout(hide_id)

    do_mouseout: (e)->
        if Preview_container.is_showing
            __clear_timeout()
            clearTimeout(tooltip_hide_id)
            DCore.Dock.require_all_region()
            launcher_mouseout_id = setTimeout(->
                update_dock_region()
            , 1000)
        else
            update_dock_region()
            setTimeout(->
                DCore.Dock.update_hide_mode()
            , 500)
