console.log=->

debugRegion = false
$DBus = {}
activeWindow = null
_dropped = false
_lastHover = null
_isDragging = false
_isDragTimer = null
_b = document.body
_dragTargetManager = null
_CW = $("#containerWrap")
changeDockRegionTimer = null
_isRightclicked = false
_isItemExpanded = false

$mousePosition =
    x: 0
    y: 0
