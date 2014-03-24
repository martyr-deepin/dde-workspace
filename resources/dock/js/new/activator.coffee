launcher_mouseout_id = null
class Activator extends AppItem
    constructor:(@id, @icon, title, @container)->
        super
        @indicatorWarp = create_element(tag:'div', class:"indicatorWarp", @element)
        @openingIndicator = create_img(src:OPENING_INDICATOR, class:"indicator OpeningIndicator", @indicatorWarp)
        @tooltip = null
        @set_tooltip(title)

    try_swap_clientgroup: ->
        @destroy_tooltip()
        group = Widget.look_up("cl_"+@id)
        if group?
            swap_element(@element, group.element)
            group.destroy()

    notify:->
        @openingIndicator.style.display = 'inline'
        @openingIndicator.style.webkitAnimationName = 'Breath'

    on_click:(e)=>
        super
        console.log "active"
        # @dbus.Activate(0,0)
        @notify()

    on_mouseover: (e)=>
        super
        Preview_close_now(Preview_container._current_group)
        DCore.Dock.require_all_region()
        clearTimeout(hide_id)

    on_mouseout:(e)=>
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

    destroy:->
        super
        @destroy_tooltip()
        calc_app_item_size()

    destroyWidthAnimation:->
        @img.classList.remove("ReflectImg")
        calc_app_item_size()
        @rotate()
        setTimeout(=>
            @destroy()
        ,500)
