_current_active_window = null
get_active_window = ->
    return _current_active_window

clientManager?.connect("ActiveWindowChanged", (xid)->
    _current_active_window = xid
)
