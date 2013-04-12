class Launcher extends AppItem
    constructor: (@id, @icon, @core)->
        super
        @app_id = @id
        @set_tooltip_text(DCore.DEntry.get_name(@core))


    try_swap_clientgroup: ->
        group = Widget.look_up("le_"+@id)
        if group?
            swap_element(@element, group.element)
            group.destroy()

    do_click: (e)->
        @flash()
        @_do_launch []

    do_itemselected: (e)->
        switch e.id
            when 1 then @_do_launch []
            when 2 then DCore.Dock.request_undock(@id)
    do_buildmenu: (e)->
        [
            [1, _("Run")],
            [],
            [2, _("Undock")],
        ]
    destroy_with_animation: ->
        @img.classList.remove("ReflectImg")
        @rotate()
        setTimeout(=>
            @destroy()
        ,500)
