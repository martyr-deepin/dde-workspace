s_width = 1280
s_height = 746
i_width = 80
i_height = 80

init_item_pos = ->
    o_table = load_occupy_table()
    #TODO: load position



load_occupy_table = ->
    o_table = localStorage.getObject("occupy_table")
    if not o_table?
        o_table = new Array()
        for i in [0..Math.floor(s_width/i_width)]
            o_table[i] = new Array(Math.floor(s_height/i_height))
    localStorage.setObject("occupy_table", o_table)
    return o_table

clear_occupy = (id) ->
    o_table = load_occupy_table()
    for row,i in o_table
        for col, j in row
            if o_table[i][j] == id
                o_table[i][j] = null
    localStorage.setObject("occupy_table", o_table)


set_occupy = (id, x, y, w, h) ->
    o_table = load_occupy_table()
    for i in [0..w-1]
        for j in [0..h-1]
            o_table[x+i][y+j] = id

    localStorage.setObject("occupy_table", o_table)

detect_occupy = (x, y, w, h) ->
    o_table = load_occupy_table()
    for i in [0..w-1]
        for j in [0..h-1]
            if o_table[x+i][y+j]?
                return false
    return true

pixel_to_position = (x, y) ->
    p_x = Math.floor(x / i_width)
    p_y = Math.floor(y / i_height)
    return [p_x, p_y]

move_to_position = (widget, x, y) ->
    if detect_occupy(x, y, 1, 1)
        widget.style.position = "fixed"
        widget.style.left = x * i_width
        widget.style.top = y * i_height
        clear_occupy(widget.id)
        set_occupy(widget.id, x, y, 1, 1)


draw_grid = (ctx) ->
    ctx.fillStyle = 'rgba(0, 100, 0, 0.1)'
    cols = window.screen.availWidth / (i_width - 10)
    rows = window.screen.availHeight / (i_height - 10)
    for i in [0..cols]
        for j in [0..rows]
            ctx.fillRect(i*i_width, j*i_height, i_width-5, i_height-5)



sort_item = ->
    for item, i in $(".item")
        x = Math.floor (i / Math.floor(s_height / i_height))
        y = Math.ceil (i % Math.floor(s_height / i_height))
        echo "sort :(#{i}, #{x}, #{y})"
        move_to_position(item, x, y)



copy_file_to_desktop = (path) ->
    Desktop.Core.run_command("cp #{path} /home/snyh/Desktop/")
    location.reload()

$("body").drop
    "drop": (evt) ->
        for file in evt.originalEvent.dataTransfer.files
            echo "find file #{file.name}"
            copy_file_to_desktop file.path
        #evt.dataTransfer.dropEffect = "move"

    "over": (evt) ->
        #echo "over"
        evt.dataTransfer.dropEffect = "move"
        evt.preventDefault()

    "enter": (evt) ->
        #evt.dataTransfer.dropEffect = "move"

    "leave": (evt) ->
        #evt.dataTransfer.dropEffect = "move"
        #

$.contextMenu({
    selector: ".item",
    callback: (key, opt) ->
        switch key
            when "reload" then location.reload()
            when "sort" then sort_item()
            when "dele" then echo opt
            when "preview" then echo "preview"
    items: {
        "preview": {name: "Preview"}
        "dele": {name: "Delete"}
        "sort": {name: "Sort Item"}
        "sepl":  "--------------",
        "reload": {name: "Reload"}
    }
})


