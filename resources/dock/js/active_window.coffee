findActiveItem = (xid)->
    for own k, v of $DBus
        item = Widget.look_up(k)
        if item and item.isApp?() and item.isActive?() and (xid in item.n_clients)
            return item
    return null

class ActiveWindow
    constructor:(xid)->
        @active_window = null
        item = findActiveItem(xid)
        if item
            @itemId = item.id



clientManager?.connect("ActiveWindowChanged", (xid)->
    console.log("ActiveWindowChanged")

    if activeWindow.itemId
        origItem = Widget.look_up(activeWindow.itemId)

    activeWindow.active_window = xid
    item = findActiveItem(xid)

    if item
        activeWindow.itemId = item.id
        item.show_open_indicator()
    else
        activeWindow.itemId = null

    origItem?.show_open_indicator()
)
