
draw_grid = (ctx) ->
    ctx.fillStyle = 'rgba(0, 100, 0, 0.1)'
    width = 80
    height = 80
    cols = window.screen.availWidth / (width - 10)
    rows = window.screen.availHeight / (height - 10)
    for i in [0..cols]
        for j in [0..rows]
            ctx.fillRect(i*width, j*height, width-5, height-5)

copy_file_to_desktop = (path) ->
    Desktop.Core.run_command("cp #{path} /home/snyh/Desktop/")

$("body").drop
    "drop": (evt) ->
        for file in evt.originalEvent.dataTransfer.files
            echo file.name
            copy_file_to_desktop file.path
        #evt.dataTransfer.dropEffect = "move"

    "over": (evt) ->
        #echo "over"
        evt.dataTransfer.dropEffect = "move"
        evt.preventDefault()

    "enter": (evt) ->
        echo "enter"
        #evt.dataTransfer.dropEffect = "move"

    "leave": (evt) ->
        echo "leave"
        #evt.dataTransfer.dropEffect = "move"
