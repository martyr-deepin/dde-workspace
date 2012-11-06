preview = document.getElementById('preview')
ctx = preview.getContext('2d')
document.body.addEventListener('mouseout', ->
)


current_id = 0
interval_id = 0
hide_timeout_id = 0

update_preview = ->
    s = DCore.Dock.fetch_window_preview(current_id, 300, 200)
    img = ctx.getImageData(0, 0, s.width, s.height)
    for v,i in s.data
        img.data[i] = v
    ctx.putImageData(img, 0, 0)

preview.addEventListener('mouseover', ->
    clearTimeout(hide_timeout_id)
)
preview.addEventListener('mouseout', ->
    preview_disactive(1000)
)

preview_disactive = (timeout) ->
    clearTimeout(hide_timeout_id)
    hide_timeout_id = setTimeout(->
                    clearInterval(interval_id)
                    ctx.clearRect(0, 0, 300, 200)
                    DCore.Dock.close_show_temp()
                timeout)

preview_active = (id, offset) ->
        preview.style.left = offset+"px"
        current_id = id
        clearInterval(interval_id)
        ctx.clearRect(0, 0, 300, 200)

        preview_disactive(3000)
        update_preview()
        interval_id = setInterval(update_preview, 600)
        DCore.Dock.show_temp_region(offset, 0, 300, 200)

preview_close_window = ->
    preview_disactive(80)



DCore.signal_connect("leave-notify", preview_close_window)
