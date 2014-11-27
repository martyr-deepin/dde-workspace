guide = null

main = ->
    guide = new Guide()
    if DEBUG
        guide?.create_page("LauncherLaunch")
    else
        guide?.create_page("Welcome")

DCore.signal_connect('primary_size_changed', (alloc)->
    echo "primary_size_changed:#{alloc.x},#{alloc.y},#{alloc.width},#{alloc.height}"
    document.body.style.position = "absolute"
    document.body.style.left = alloc.x
    document.body.style.top = alloc.y
    document.body.style.height = alloc.height
    document.body.style.width = alloc.width

    primary_info.x = alloc.x
    primary_info.y = alloc.y
    primary_info.width = alloc.width
    primary_info.height = alloc.height

    COLLECT_WIDTH = primary_info.width - COLLECT_LEFT * 2
    COLLECT_APP_ROWS = Math.floor((COLLECT_APP_NUMBERS * EACH_APP_WIDTH + (COLLECT_APP_NUMBERS - 1) * EACH_APP_MARGIN_LEFT) / COLLECT_WIDTH)
    COLLECT_HEIGHT = COLLECT_APP_ROWS * EACH_APP_HEIGHT + (COLLECT_APP_ROWS - 1) * EACH_APP_MARGIN_TOP
    APP_NUM_MAX_IN_ONE_ROW = Math.floor((COLLECT_WIDTH + EACH_APP_MARGIN_LEFT) / (EACH_APP_WIDTH + EACH_APP_MARGIN_LEFT))
    main()
)

DCore.Guide.emit_webview_ok()
