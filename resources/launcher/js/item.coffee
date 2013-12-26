#Copyright (c) 2011 ~ 2013 Deepin, Inc.
#              2013 ~ 2013 Li Liqiang
#
#Author:      Li Liqiang <liliqiang@linuxdeepin.com>
#Maintainer:  Li Liqiang <liliqiang@linuxdeepin.com>
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
    @clean_hover_temp: false
    @display_temp: false
    constructor: (@id, @core)->
        super
        @load_image()
        @status = SOFTWARE_STATE.IDLE
        @name = create_element("div", "item_name", @element)
        name = DCore.DEntry.get_name(@core)
        @name.innerText = name
        @element.draggable = true
        @element.style.display = "none"
        try_set_title(@element, name, 80)
        @display_mode = 'display'
        @is_autostart = DCore.Launcher.is_autostart(@core)
        if @is_autostart
            Item.theme_icon ?= DCore.get_theme_icon(AUTOSTART_ICON_NAME,
                AUTOSTART_ICON_SIZE)
            create_img("autostart_flag", Item.theme_icon, @element)

    destroy: ->
        grid.removeChild(@element)
        super

    update: (core)->
        # TODO: update category infos
        @core = core
        @name.innerText = DCore.DEntry.get_name(@core)
        im = DCore.DEntry.get_icon(@core)
        if im == null
            im = DCore.get_theme_icon('invalid-dock_app', ITEM_IMG_SIZE)
        @img.src = im

    load_image: ->
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

    do_rightclick: (e)->
        e.preventDefault()
        e.stopPropagation()
        @menu = null
        @menu = new Menu(
            DEEPIN_MENU_TYPE.NORMAL,
            new MenuItem(1, _("_Open")),
            new MenuSeparator(),
            new MenuItem(2, ITEM_HIDDEN_ICON_MESSAGE[@display_mode]),
            new MenuSeparator(),
            # new MenuItem(id, _("_Pin")/_("_Unpin")),
            # new MenuSeparator(),
            new MenuItem(3, _("Send to d_esktop")).setActive(
                not DCore.Launcher.is_on_desktop(@core)
            ),
            new MenuItem(4, _("Send to do_ck")).setActive(s_dock != null),
            new MenuSeparator(),
            new MenuItem(5, AUTOSTARTUP_MESSAGE[@is_autostart]),
            new MenuSeparator(),
            # if has_update
            #     new MenuItem(id, "Update"),
            #     new MenuItem(id, "Update All"),
            #     new MenuSeparator(),
            new MenuItem(6, _("_Uninstall"))
        )

        if DCore.DEntry.internal()
            @menu.addSeparator().append(
                new MenuItem(100, "report this bad icon")
            )

        @menu.addListener(@on_itemselected).showMenu(e.screenX, e.screenY)

    on_itemselected: (id)=>
        id = parseInt(id)
        switch id
            when 1 then DCore.DEntry.launch(@core, [])
            when 2 then @toggle_icon()
            when 3 then DCore.DEntry.copy_dereference_symlink([@core], DCore.Launcher.get_desktop_entry())
            when 4 then s_dock.RequestDock_sync(DCore.DEntry.get_uri(@core).substring(7))
            when 5 then @toggle_autostart()
            when 6
                if confirm("This operation may lead to uninstalling other corresponding softwares. Are you sure to uninstall this Item?")
                    @status = SOFTWARE_STATE.UNINSTALLING
                    @hide()
                    uninstalling_apps[@id] = @
                    DCore.Launcher.uninstall(@core, true)
            when 100 then DCore.DEntry.report_bad_icon(@core)  # internal

    hide_icon: (e)=>
        @display_mode = 'hidden'
        if HIDE_ICON_CLASS not in @element.classList
            @add_css_class(HIDE_ICON_CLASS, @element)
        if not Item.display_temp and not is_show_hidden_icons
            @element.style.display = 'none'
            Item.display_temp = false
        hidden_icons[@id] = @
        save_hidden_apps()
        hide_category()
        if _get_hidden_icons_ids().length == 0
            _update_scroll_bar(category_infos[selected_category_id].length - _get_hidden_icons_ids().length)
            Item.display_temp = false

    display_icon: (e)=>
        @display_mode = 'display'
        @element.style.display = 'block'
        if HIDE_ICON_CLASS in @element.classList
            @remove_css_class(HIDE_ICON_CLASS, @element)
        delete hidden_icons[@id]
        save_hidden_apps()
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

    add_to_autostart: ->
        if DCore.Launcher.add_to_autostart(@core)
            @is_autostart = true
            Item.theme_icon ?= DCore.get_theme_icon(AUTOSTART_ICON_NAME,
                AUTOSTART_ICON_SIZE)
            last = @element.lastChild
            if last.tagName != 'IMG'
                create_img("autostart_flag", Item.theme_icon, @element)

    remove_from_autostart: ->
        if DCore.Launcher.remove_from_autostart(@core)
            @is_autostart = false
            last = @element.lastChild
            if last.tagName == 'IMG'
                @element.removeChild(last)

    toggle_autostart: ->
        if @is_autostart
            @remove_from_autostart()
        else
            @add_to_autostart()

    hide: ->
        @element.style.display = "none"

    # use '->', Item.display_temp and @display_mode will be undifined when this
    # function is pass to some other functions like setTimeout
    show: =>
        if (Item.display_temp or @display_mode == 'display') and @status == SOFTWARE_STATE.IDLE
            @element.style.display = "block"

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
        Item.hover_item_id = @id
        if not Item.clean_hover_temp
            @element.style.background = "rgba(255, 255, 255, 0.15)"
            @element.style.border = "1px rgba(255, 255, 255, 0.25) solid"
            @element.style.borderRadius = "4px"

    do_mouseout: =>
        @element.style.border = "1px rgba(255, 255, 255, 0.0) solid"
        @element.style.background = ""
        @element.style.borderRadius = ""
        # Item.hover_item_id = null

