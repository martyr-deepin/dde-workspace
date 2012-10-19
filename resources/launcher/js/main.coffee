do_workarea_changed = (alloc)->
    document.body.style.width = alloc.width
    document.body.style.height = alloc.height

DCore.signal_connect('workarea_changed', do_workarea_changed)



create_category = (info) ->
    el = document.createElement('div')
    el.setAttribute('class', 'category_name')
    el.setAttribute('cat_id', info.ID)
    el.innerHTML = "
    <div>#{info.Name}</div>
    "
    el.addEventListener('click', (e) ->
        grid_load_category(info.ID)
    )
    return el



append_to_category = (cat) ->
    document.getElementById('category').appendChild(cat)

for info in DCore.Launcher.get_categories()
    c = create_category(info)
    append_to_category(c)



grid_load_category(0) #the All applications' ID is zero.
