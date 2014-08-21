guide = null

DCore.signal_connect('primary_size_changed', (alloc)->
    echo "primary_size_changedd:#{alloc.x},#{alloc.y},#{alloc.width},#{alloc.height}"
    primary_info.x = alloc.x
    primary_info.y = alloc.y
    primary_info.width = alloc.width
    primary_info.height = alloc.height
    document.body.style.height = alloc.height
    document.body.style.width = alloc.width
    guide = new Guide() if not guide?
    guide?.set_size(alloc)
    guide?.create_page("Welcome")

    COLLECT_WIDTH = primary_info.width - COLLECT_LEFT * 2
    COLLECT_APP_LINE_NUM = Math.ceil((COLLECT_APP_NUMBERS * EACH_APP_WIDTH + (COLLECT_APP_NUMBERS - 1) * EACH_APP_MARGIN_LEFT) / COLLECT_WIDTH)
    COLLECT_HEIGHT = COLLECT_APP_LINE_NUM * EACH_APP_HEIGHT + (COLLECT_APP_LINE_NUM - 1) * EACH_APP_MARGIN_TOP
)

guide = new Guide()
DCore.Guide.emit_webview_ok()
