basename = (path)->
    path.replace(/\\/g,'/').replace(/.*\//,)
    
s_box = $('#s_box')

search = ->
    ret = []
    key = s_box.value.toLowerCase()

    for k of applications
        if key == ""
            ret.push(k)
        else if basename(k).toLowerCase().indexOf(key) >0
            ret.push(k)
    grid_show_items(ret)
    return ret

s_box.addEventListener('input', s_box.blur())

document.body.onkeypress = (e) ->
    switch e.which
        when 27
            if s_box.value == ""
                DCore.Launcher.exit_gui()
            else
                s_box.value = ""
        when 8
            s_box.value = s_box.value.substr(0, s_box.value.length-1)
        when 13
            $('#grid').children[0].click_cb()
        else
            s_box.value += String.fromCharCode(e.which)
    search()
