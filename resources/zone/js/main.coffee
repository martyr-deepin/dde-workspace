zone = null

DCore.signal_connect('primary_size_changed', (alloc)->
    document.body.style.height = alloc.height
    document.body.style.width = alloc.width
    echo "primary_size_changedd:#{alloc.x},#{alloc.y},#{alloc.width},#{alloc.height}"
    zone = new Zone() if not zone?
    zone?.set_size(alloc)
    zone?.option_build()
)

DCore.Zone.emit_webview_ok()
zone = new Zone() if not zone?

document.body.addEventListener("click",(e)=>
    e.stopPropagation()
    return if DEBUG
    enableZoneDetect(true)
    DCore.Zone.quit()
)

document.body.addEventListener("contextmenu",(e)=>
    e.preventDefault()
    e.stopPropagation()
)

