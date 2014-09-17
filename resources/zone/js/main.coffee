zone = null

main = ->
    zone = new Zone()
    zone?.option_build()

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

DCore.signal_connect('primary_size_changed', (alloc)->
    echo "primary_size_changed:#{alloc.x},#{alloc.y},#{alloc.width},#{alloc.height}"
    document.body.style.position = "absolute"
    document.body.style.left = alloc.x
    document.body.style.top = alloc.y
    document.body.style.height = alloc.height
    document.body.style.width = alloc.width
    main()
)

DCore.Zone.emit_webview_ok()
