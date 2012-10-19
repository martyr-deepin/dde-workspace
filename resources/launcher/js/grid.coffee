applications = {}
category_infos = []

create_item = (info) ->
    el = document.createElement('div')
    el.setAttribute('class', 'item')
    el.id = info.EntryPath
    el.innerHTML = "
    <img draggable=false src=#{info.Icon} />
    <div class=item_name> #{info.Name}</div>
    <div class=item_comment>#{info.Comment}</div>
    "
    el.click_cb = (e) ->
        el.style.cursor = "wait"
        flag = info.Exec.indexOf("%")
        if (flag > 0)
            exec = info.Exec.substr(0, flag)
        else
            exec = info.Exec
        DCore.run_command(exec)
        DCore.Launcher.exit()
    el.addEventListener('click', el.click_cb)
    return el

for info in DCore.Launcher.get_items()
    applications[info.EntryPath] = create_item(info)
# load the Desktop Entry's infomations.

#export function
grid_show_items = (items) ->
    grid.innerHTML = ""
    for i in items
        grid.appendChild(applications[i])

grid = document.getElementById('grid')
grid_load_category = (cat_id) ->
    if cat_id == 0
        grid.innerHTML = ""
        for own key, value of applications
            grid.appendChild(value)
        return

    if category_infos[cat_id]
        info = category_infos[cat_id]
    else
        info = DCore.Launcher.get_items_by_category(cat_id)
        category_infos[cat_id] = info

    grid_show_items(info)
