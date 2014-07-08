# console.log=->

_dropped = false
_lastHover = null
_isDragging = false
_isDragTimer = null
_b = document.body
_dragTargetManager = null
_CW = $("#containerWarp")
changeDockRegionTimer = null
_isRightclicked = false

$mousePosition =
    x: 0
    y: 0
