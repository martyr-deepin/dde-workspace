_category = $("#category")

_select_category_timeout_id = 0
selected_category_id = ALL_APPLICATION_CATEGORY_ID
_create_category = (info) ->
    el = document.createElement('div')

    el.setAttribute('class', 'category_name')
    el.setAttribute('cat_id', info.ID)
    el.innerText = info.Name

    el.addEventListener('click', (e) ->
        e.stopPropagation()
    )
    el.addEventListener('mouseover', (e)->
        e.stopPropagation()
        if info.ID != selected_category_id
            s_box.value = "" if s_box.value != ""
            _select_category_timeout_id = setTimeout(
                ->
                    grid_load_category(info.ID)
                    selected_category_id = info.ID
                , 25)
    )
    el.addEventListener('mouseout', (e)->
        if _select_category_timeout_id != 0
            clearTimeout(_select_category_timeout_id)
    )
    return el


_set_adaptive_height = ->
    warp = _category.parentNode
    # add 20px for margin
    categories_height = _category.children.length * (_category.lastElementChild.clientHeight + 20)
    if categories_height > warp.clientHeight
        warp.style.overflowY = "scroll"
        warp.style.marginBottom = "#{GRID_MARGIN_BOTTOM}px"


init_category_list = ->
    frag = document.createDocumentFragment()
    for info in DCore.Launcher.get_categories()
        c = _create_category(info)
        frag.appendChild(c)
    _category.appendChild(frag)

    _set_adaptive_height()
