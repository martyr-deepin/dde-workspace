item_selected = null

clean_hover_state = do ->
    hover_timeout_id = null
    ->
        Item.clean_hover_temp = true
        event = new Event("mouseout")
        Widget.look_up(Item.hover_item_id)?.element.dispatchEvent(event)
        clearTimeout(hover_timeout_id)
        hover_timeout_id = setTimeout(->
            Item.clean_hover_temp = false
            event = new Event("mouseover")
            Widget.look_up(Item.hover_item_id)?.element.dispatchEvent(event)
        , 1100)

get_item_row_count = ->
    parseInt(grid.clientWidth / ITEM_WIDTH)

update_selected = (el)->
    item_selected?.unselect()
    item_selected = el
    item_selected?.select()

get_first_shown = ->
    first_item = applications[$(".item").id]
    if first_item.is_shown()
        first_item
    else
        first_item.next_shown()

selected_next = ->
    clean_hover_state()
    if not item_selected
        item_selected = get_first_shown()
        update_selected(item_selected)
        item_selected?.scroll_to_view()
        return
    n = item_selected.next_shown()
    if n
        n.scroll_to_view()
        update_selected(n)
selected_prev = ->
    clean_hover_state()
    if not item_selected
        item_selected = get_first_shown()
        update_selected(item_selected)
        item_selected?.scroll_to_view()
        return
    n = item_selected.prev_shown()
    if n
        n.scroll_to_view()
        update_selected(n)

selected_down = ->
    clean_hover_state()
    if not item_selected
        item_selected = get_first_shown()
        update_selected(item_selected)
        item_selected?.scroll_to_view()
        return
    n = item_selected
    for i in [0..get_item_row_count()-1]
        if n
            n.scroll_to_view()
            n = n.next_shown()
    if n
        n.scroll_to_view()
        update_selected(n)
    grid.scrollTop += SCROLL_STEP_LEN

selected_up = ->
    clean_hover_state()
    if not item_selected
        item_selected = get_first_shown()
        update_selected(item_selected)
        item_selected?.scroll_to_view()
        return
    n = item_selected
    for i in [0..get_item_row_count()-1]
        if n
            n.scroll_to_view()
            n = n.prev_shown()
    if n
        n.scroll_to_view()
        update_selected(n)
    grid.scrollTop -= SCROLL_STEP_LEN
