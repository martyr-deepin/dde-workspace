itemDBus = (path)->
    name: "com.deepin.daemon.Dock"
    path: path
    interface: "dde.dock.EntryProxyer"

$DBus = {}

createItem = (d)->
    icon = d.Data[ITEM_DATA_FIELD.icon] || NOT_FOUND_ICON
    if !(icon.indexOf("data:") != -1 or icon[0] == '/' or icon.indexOf("file://") != -1)
        icon = DCore.get_theme_icon(icon, 48)

    title = d.Data[ITEM_DATA_FIELD.title] || "Unknow"

    $DBus[d.Id] = d
    if d.Type == ITEM_TYPE.app
        container = app_list.element

        console.log("AppItem #{d.Id}")
        new AppItem(d.Id, icon, title, container)
    else if d.Id == TIME_ID
        console.log("AppletDateTime")
        time.core = new EntryProxy(d)
        time.init_clientgroup()
        time.core.showQuickWindow()
    else
        console.log("SystemItem #{d.Id}, #{icon}, #{title}")
        new SystemItem(d.Id, icon, title)

    if not Preview_container.is_showing
        return
    Preview_container._current_group


deleteItem = (id)->
    delete $DBus[id]
    # id = path.substr(path.lastIndexOf('/') + 1)
    i = Widget.look_up(id)
    if i
        i.destroy()
    else
        # console.log("#{id} not eixst")


iconCanvas = create_element(tag:'canvas', document.body)
iconCanvas.width = iconCanvas.height = 48
iconCanvas.style.position = 'absolute'
iconCanvas.style.top = -screen.height

bright_image = (img, adjustment)->
    ctx = iconCanvas.getContext("2d")
    # clear the last icon.
    ctx.clearRect(0, 0, iconCanvas.width, iconCanvas.height)
    ctx.drawImage(img, 0, 0, iconCanvas.width, iconCanvas.height)
    origDataUrl = iconCanvas.toDataURL()
    dataUrl = DCore.Dock.bright_image(origDataUrl, adjustment)
    # i = new Image()
    # i.src = dataUrl
    # i.onload = ->
    #     ctx.drawImage(i, 0, 0)
    return dataUrl

dark_image = (img, adjustment)->
    ctx = iconCanvas.getContext("2d")
    # clear the last icon.
    ctx.clearRect(0, 0, iconCanvas.width, iconCanvas.height)
    ctx.drawImage(img, 0, 0, iconCanvas.width, iconCanvas.height)
    origDataUrl = iconCanvas.toDataURL()
    dataUrl = DCore.Dock.dark_image(origDataUrl, adjustment)
    # i = new Image()
    # i.src = dataUrl
    # i.onload = ->
    #     ctx.drawImage(i, 0, 0)
    return dataUrl

updatePanel = ->
    _isDragging = false
    panel.updateWithAnimation()
    setTimeout(->
        panel.cancelAnimation()
    , 300)


getSiblingFromPoint = (x, y, sentinel, step, stepHandler)->
    el = null
    while 1
        x = stepHandler(x, step)
        el = document.elementFromPoint(x, y)
        console.log("#{x}, #{y}")
        console.log(el)
        if not el
            console.log("failed")
            return null if not el
        if el.classList?.contains("AppItemImg")
            id = el.parentNode.parentNode.parentNode.id
            console.log(id)
            if id == sentinel
                console.log("get self")
                return null
            return el
        else if el.tagName == "BODY"
            console.log("FOUND BODY")
            return null

getPreviousSiblingFromPoint = (x, y, sentinel, step=6)->
    getSiblingFromPoint(x, y, sentinel, step, (x, step)->x - step)

getNextSiblingFromPoint = (x, y, sentinel, step=6)->
    getSiblingFromPoint(x, y, sentinel, step, (x, step)->x + step)
