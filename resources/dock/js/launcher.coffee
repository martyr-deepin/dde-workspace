class Launcher extends AppItem
    constructor: (@id, @icon, @core)->
        super
        @element.setAttribute("title", "APPID:#{@id}")

    try_swap_clientgroup: ->
        group = Widget.look_up("le_"+@id)
        if group?
            swap_element(@element, group.element)
            group.destroy()

    do_click: (e)->
        DCore.DEntry.launch(@core, [])

    do_itemselected: (e)->
        switch e.id
            when 1 then DCore.DEntry.launch(@core, [])
            when 2 then DCore.Dock.request_undock(@id)
    do_buildmenu: (e)->
        [
            [1, _("Run")],
            [],
            [2, _("UnDock")],
        ]

