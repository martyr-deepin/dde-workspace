$EW = DCore.EXWindow
class EmbedWindow
    constructor:(xids, resize)->
        @xids = []
        for xid in xids
            @xids.push(xid.Xid)
            $EW.create(xid.Xid, resize)

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
