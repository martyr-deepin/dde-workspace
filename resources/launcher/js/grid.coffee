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

applications = {}
category_infos = []

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
    constructor: (@id, @core)->
        super
        @img = create_img("", DCore.DEntry.get_icon(@core), @element)
        @name = create_element("div", "item_name", @element)
        @name.innerText = DCore.DEntry.get_name(@core)
        @element.draggable = true
        @element.style.display = "none"
        try_set_title(@element, DCore.DEntry.get_name(@core), 80)

    do_click : (e)->
        e?.stopPropagation()
        @element.style.cursor = "wait"
        DCore.DEntry.launch(@core, [])
        DCore.Launcher.exit_gui()
    do_mouseover: (e)->
        #$("#close").setAttribute("class", "close_hover")

    do_dragstart: (e)->
        e.dataTransfer.setData("text/uri-list", DCore.DEntry.get_uri(@core))
        e.dataTransfer.setDragImage(@img, 20, 20)
        e.dataTransfer.effectAllowed = "all"

    do_buildmenu: (e)->
        [
            [1, _("Open")],
            [],
            [2, _("Send to desktop")],
            [3, _("Send to dock"), s_dock!=null],
        ]
    do_itemselected: (e)=>
        switch e.id
            when 1 then DCore.DEntry.launch(@core, [])
            when 2 then DCore.DEntry.copy([@core], DCore.Launcher.get_desktop_entry())
            when 3 then s_dock.RequestDock_sync(DCore.DEntry.get_uri(@core).substring(7))
    hide: =>
        @element.style.display = "none"
    show: =>
        @element.style.display = "block"
    is_shown: =>
        @element.style.display == "block"
    selecte: =>
        @element.setAttribute("class", "item item_selected")
    unselecte: =>
        @element.setAttribute("class", "item")
    next_shown: =>
        next_sibling_id = @element.nextElementSibling?.id
        if next_sibling_id
            n = applications[next_sibling_id]
            if n.is_shown() then n else n.next_shown()
        else
            null
    prev_shown: =>
        prev_sibling_id = @element.previousElementSibling?.id
        if prev_sibling_id
            n = applications[prev_sibling_id]
            if n.is_shown() then n else n.prev_shown()
        else
            null


# get all applications and sort them by name
_all_items = DCore.Launcher.get_items()
_all_items.sort((lhs, rhs) ->
    lhs_name = DCore.DEntry.get_name(lhs)
    rhs_name = DCore.DEntry.get_name(rhs)

    if lhs_name > rhs_name
        1
    else if lhs_name == rhs_name
        0
    else
        -1
)
for core in _all_items
    id = DCore.DEntry.get_id(core)
    applications[id] = new Item(id, core)
# load the Desktop Entry's infomations.

update_items = (items) ->
    child_nodes = grid.childNodes
    for id in items
        item_to_be_shown = grid.removeChild($("#"+id))
        grid.appendChild(item_to_be_shown)

`const ITEM_WIDTH = 122`
`const ITEM_HEIGHT = 132`
update_scroll_bar = (items) ->
    lines = parseInt(ITEM_WIDTH * items.length / grid.clientWidth) + 1

    if lines * ITEM_HEIGHT >= grid.clientHeight
        grid.style.overflowY = "scroll"
    else
        grid.style.overflowY = "hidden"

#export function
grid_show_items = (items, is_category) ->
    item_selected = null
    update_scroll_bar(items)

    for own key, value of applications
        if key not in items
            value.hide()

    if not is_category
        update_items(items)

    `const NUM_SHOWN_ONCE = 10`
    count = 0
    for id in items
        group_num = parseInt(count++ / NUM_SHOWN_ONCE)
        setTimeout(applications[id].show, 4 + group_num)

show_grid_selected = (id)->
    cns = $s(".category_name")
    for c in cns
        if `id == c.getAttribute("cat_id")`
            c.setAttribute("class", "category_name category_selected")
        else
            c.setAttribute("class", "category_name")

grid = $('#grid')
grid_load_category = (cat_id) ->
    show_grid_selected(cat_id)

    if not category_infos[cat_id]
        if cat_id == -1
            frag = document.createDocumentFragment()
            category_infos[cat_id] = []
            for own key, value of applications
                frag.appendChild(value.element)
                category_infos[cat_id].push(key)
            grid.appendChild(frag)
        else
            info = DCore.Launcher.get_items_by_category(cat_id).sort()
            category_infos[cat_id] = info

    grid_show_items(category_infos[cat_id], true)
    update_selected(null)

