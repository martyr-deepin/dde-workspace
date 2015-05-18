$EW = DCore.EXWindow
$EW_MAP = {}
$EWType =
    Unknown: 0
    Plugin:1
    TrayIcon:2
class EmbedWindow
    constructor:(xids, resize, @type)->
        @xids = []
        for xid in xids
            @xids.push(xid.Xid)
            $EW.create(xid.Xid, resize, @type)
            $EW.hide(xid.Xid)

    window_size:(xid)->
        $EW.window_size(xid)

    move:(xid, x, y)->
        $EW.move(xid, x, y)

    move_resize:(xid, x, y, width, height)->
        $EW.move_resize()

    show:(xid=null)->
        if xid
            $EW.show(xid)
        else
            for xid in @xids
                $EW.show(xid)

    hide:(xid=null)->
        if xid
            $EW.hide(xid)
        else
            for xid in @xids
                $EW.hide(xid)

    draw_to_canvas: (xid, canvas)->
        if !canvas
            canvas = xid
            for xid in @xids
                $EW.draw_to_canvas(xid, canvas)
            return
        $EW.draw_to_canvas(xid, canvas)

    undraw:->
        $EW.undraw()
