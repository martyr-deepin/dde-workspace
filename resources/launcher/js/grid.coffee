#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#Maintainer:  snyh <snyh@snyh.org>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.

grid = $('#grid')

try_set_title = (el, text, width)->
    setTimeout(->
        height = calc_text_size(text, width)
        if height > 38
            el.setAttribute('title', text)
    , 200)

try
    s_dock = DCore.DBus.session("com.deepin.dde.dock")
catch error
    s_dock = null


class Item extends Widget
    @theme_icon: null
    @hover_item_id: null
    @display_temp: false
    constructor: (@id, @core)->
        super
        im = DCore.DEntry.get_icon(@core)
        if im == null
            im = DCore.get_theme_icon('invalid-dock_app', ITEM_IMG_SIZE)
        @img = create_img("", im, @element)
        @img.onload = (e) =>
            if @img.width == @img.height
                @img.className = 'square_img'
            else if @img.width > @img.height
                @img.className = 'hbar_img'
                new_height = ITEM_IMG_SIZE * @img.height / @img.width
                grap = (ITEM_IMG_SIZE - Math.floor(new_height)) / 2
                @img.style.padding = "#{grap}px 0px"
            else
                @img.className = 'vbar_img'
        @img.onerror = (e) =>
            src = DCore.get_theme_icon('invalid-dock_app', ITEM_IMG_SIZE)
            if src != @img.src
                @img.src = src
        @name = create_element("div", "item_name", @element)
        @name.innerText = DCore.DEntry.get_name(@core)
        @element.draggable = true
        @element.style.display = "none"
        try_set_title(@element, DCore.DEntry.get_name(@core), 80)
        @display_mode = 'display'
        @is_autostart = DCore.Launcher.is_autostart(@core)
        if @is_autostart
            Item.theme_icon ?= DCore.get_theme_icon(AUTOSTART_ICON_NAME,
                AUTOSTART_ICON_SIZE)
            create_img("autostart_flag", Item.theme_icon, @element)

    do_click : (e)=>
        e?.stopPropagation()
        @element.style.cursor = "wait"
        DCore.DEntry.launch(@core, [])
        Item.hover_item_id = @id
        @element.style.cursor = "auto"
        exit_launcher()

    do_dragstart: (e)=>
        e.dataTransfer.setData("text/uri-list", DCore.DEntry.get_uri(@core))
        e.dataTransfer.setDragImage(@img, 20, 20)
        e.dataTransfer.effectAllowed = "all"

    _menu: ->
        if @display_mode == 'display'
            hide_icon_msg = HIDE_ICON
        else
            hide_icon_msg = DISPLAY_ICON

        if @is_autostart
            startup_msg = NOT_STARTUP_ICON
        else
            startup_msg = STARTUP_ICON
        menu = [
            [1, _("_Open")],
            [],
            [2, hide_icon_msg],
            [],
            [3, _("Send to d_esktop"), not DCore.Launcher.has_this_item_on_desktop(@core)],
            [4, _("Send to do_ck"), s_dock!=null],
            [],
            [5, startup_msg]
        ]

        if DCore.DEntry.internal()
            menu.push([])
            menu.push([100, "report this bad icon"])

        menu

    @_contextmenu_callback: do ->
        _callback_func = null
        (item)->
            f = (e) ->
                item.element.removeEventListener('contextmenu', _callback_func)
                item.element.contextMenu = build_menu(item._menu())
                _callback_func = f

    do_buildmenu: (e)=>
        @_menu()

    hide_icon: (e)=>
        @display_mode = 'hidden'
        if HIDE_ICON_CLASS not in @element.classList
            @add_css_class(HIDE_ICON_CLASS, @element)
        if not Item.display_temp and not is_show_hidden_icons
            @element.style.display = 'none'
            Item.display_temp = false
        hidden_icons[@id] = @
        hide_category()
        _update_scroll_bar(category_infos[selected_category_id].length - _get_hidden_icons_ids().length)

    display_icon: (e)=>
        @display_mode = 'display'
        @element.style.display = 'block'
        if HIDE_ICON_CLASS in @element.classList
            @remove_css_class(HIDE_ICON_CLASS, @element)
        delete hidden_icons[@id]
        hidden_icons_num = _get_hidden_icons_ids().length
        show_category()
        if hidden_icons_num == 0
            is_show_hidden_icons = false
            _show_hidden_icons(is_show_hidden_icons)
        _update_scroll_bar(category_infos[selected_category_id].length - hidden_icons_num)

    display_icon_temp: ->
        @element.style.display = 'block'
        Item.display_temp = true
        show_category()

    toggle_icon: ->
        if @display_mode == 'display'
            @hide_icon()
        else
            @display_icon()

        @element.addEventListener('contextmenu', Item._contextmenu_callback(@))

    add_to_autostart: ->
        @is_autostart = true
        DCore.Launcher.add_to_autostart(@core)
        Item.theme_icon ?= DCore.get_theme_icon(AUTOSTART_ICON_NAME,
            AUTOSTART_ICON_SIZE)
        create_img("autostart_flag", Item.theme_icon, @element)

    remove_from_autostart: ->
        if DCore.Launcher.remove_from_autostart(@core)
            @is_autostart = false
            last = @element.lastChild
            @element.removeChild(last) if last.tagName == 'IMG'

    toggle_autostart: ->
        if @is_autostart
            @remove_from_autostart()
        else
            @add_to_autostart()

    do_itemselected: (e)=>
        switch e.id
            when 1 then DCore.DEntry.launch(@core, [])
            when 2 then @toggle_icon()
            when 3 then DCore.DEntry.copy_dereference_symlink([@core], DCore.Launcher.get_desktop_entry())
            when 4 then s_dock.RequestDock_sync(DCore.DEntry.get_uri(@core).substring(7))
            when 5 then @toggle_autostart()
            when 100 then DCore.DEntry.report_bad_icon(@core)  # internal
    hide: ->
        @element.style.display = "none"

    # use '->', Item.display_temp and @display_mode will be undifined when this
    # function is pass to some other functions like setTimeout
    show: =>
        @element.style.display = "block" if Item.display_temp or @display_mode == 'display'

    is_shown: ->
        @element.style.display == "block"

    select: ->
        @element.setAttribute("class", "item item_selected")

    unselect: ->
        @element.setAttribute("class", "item")

    next_shown: ->
        next_sibling_id = @element.nextElementSibling?.id
        if next_sibling_id
            n = applications[next_sibling_id]
            if n.is_shown() then n else n.next_shown()
        else
            null

    prev_shown: ->
        prev_sibling_id = @element.previousElementSibling?.id
        if prev_sibling_id
            n = applications[prev_sibling_id]
            if n.is_shown() then n else n.prev_shown()
        else
            null

    scroll_to_view: ->
        @element.scrollIntoViewIfNeeded()

    do_mouseover: =>
        @element.style.background = "rgba(0, 183, 238, 0.2)"
        @element.style.border = "1px rgba(255, 255, 255, 0.2) solid"
        @element.style.borderRadius = "2px"
        Item.hover_item_id = @id

    do_mouseout: =>
        @element.style.border = "1px rgba(255, 255, 255, 0.0) solid"
        @element.style.background = ""
        @element.style.borderRadius = ""
        # Item.hover_item_id = null


update_items = (items) ->
    for id in items
        item_to_be_shown = grid.removeChild($("#"+id))
        grid.appendChild(item_to_be_shown)
    return items

_update_scroll_bar = (len) ->
    lines = parseInt(ITEM_WIDTH * len / grid.clientWidth) + 1

    if lines * ITEM_HEIGHT >= grid.clientHeight
        grid.style.overflowY = "scroll"
    else
        grid.style.overflowY = "hidden"

grid_show_items = (items) ->
    update_selected(null)

    hidden_icon_ids = _get_hidden_icons_ids()
    count = 0
    for i in items
        if i not in hidden_icon_ids
            count += 1
    _update_scroll_bar(count)

    for own key, value of applications
        if key not in items
            value.hide()

    count = 0
    for id in items
        group_num = parseInt(count++ / NUM_SHOWN_ONCE)
        setTimeout(applications[id].show, 4 + group_num)

    return  # some return like here will keep js converted by coffeescript returning stupid things

_show_grid_selected = (id)->
    cns = $s(".category_name")
    for c in cns
        if `id == c.getAttribute("cat_id")`
            c.classList.add('category_selected')
        else
            c.classList.remove('category_selected')
    return

grid_load_category = (cat_id) ->
    _show_grid_selected(cat_id)
    grid_show_items(category_infos[cat_id])
    update_selected(null)


init_grid = ->
    sort_category_info(sort_methods[sort_method])
    update_items(category_infos[ALL_APPLICATION_CATEGORY_ID])
    grid_load_category(ALL_APPLICATION_CATEGORY_ID)

show_grid_dom_child = ->
    c = grid.children
    i = 0
    while i < c.length
        echo "#{get_name_by_id(c[i].id)}"
        i = i + 1
