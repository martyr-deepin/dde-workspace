m = new DeepinMenu()
i1 = new DeepinMenuItem(1, "Open")
i2 = new DeepinMenuItem(2, "delete")
m.appendItem(i1)
m.appendItem(i2)

shorten_text= (str, n) ->
    r = /[^\x00-\xff]/g
    if str.replace(r, "mm").length <= n
        return str

    mid = Math.floor(n / 2)
    n = n - 3
    for i in [mid..(str.length - 1)]
        if str.substr(0, i).replace(r, "mm").length >= n
            return str.substr(0, i - 1) + "..."

    return str

class Item extends Widget
    constructor: (@name, @icon, @exec, @path) ->
        @id = @path
        super

        el = @element
        info = {x:0, y:0, width:1, height:1}

        el.setAttribute("tabindex", 0)
        el.draggable = true
        el.innerHTML = "
        <img draggable=false src=#{@icon} />
        <div class=item_name>#{shorten_text(@name, 20)}</div>
        "

        # search the div for store the name
        @item_name = sub_item for sub_item in el.childNodes when sub_item.className == "item_name"

        @element.addEventListener('click', ->
            if this.className.search(/item_selected/i) > -1
                this.className = this.className.replace(" item_selected", "")
            else
                this.className += " item_selected"
        )

        @element.addEventListener('dblclick', ->
            Desktop.Core.run_command exec
        )
        @init_drag?()
        @init_drop?()
        #@init_keypress?()
        @element.contextMenu = m

    item_focus: ->
        @element.className.replace(" item_selected", "")

    item_blur: ->
        @element.className += " item_selected"

    rename: (new_name) ->
        @item_name.innerText = new_name

    destroy: ->
        info = load_position(this)
        clear_occupy(info)
        super

    init_keypress: ->
        document.designMode = 'On'
        @element.addEventListener('keydown', (evt)->
            switch (evt.which)
                when 113
                    echo "Rename"
        )


class DesktopEntry extends Item
    init_drag: ->
        el = @element
        el.addEventListener('dragstart', (evt) =>
                evt.dataTransfer.setData("text/uri-list", "file://#{@path}")
                evt.dataTransfer.setData("text/plain", "#{@name}")
                evt.dataTransfer.effectAllowed = "all"
        )
        el.addEventListener('dragend', (evt) =>
                if evt.dataTransfer.dropEffect == "move"
                    evt.preventDefault()
                    node = evt.target
                    pos = pixel_to_position(evt.x, evt.y)

                    info = localStorage.getObject(@path)
                    info.x = pos[0]
                    info.y = pos[1]
                    move_to_position(this, info)

                else if evt.dataTransfer.dropEffect == "link"
                    node = evt.target
                    node.parentNode.removeChild(node)
        )

class Folder extends DesktopEntry
    icon_open: ->
        $(@element).find("img")[0].src = Desktop.Core.get_folder_open_icon();
    icon_close: ->
        $(@element).find("img")[0].src = Desktop.Core.get_folder_close_icon();


    init_drop: =>
        $(@element).drop
            drop: (evt) =>
                file = evt.dataTransfer.getData("text/uri-list")
                evt.preventDefault()
                @icon_close()
                @move_in(file)

            over: (evt) =>
                evt.preventDefault()
                path = evt.dataTransfer.getData("text/uri-list")
                if path == "file://#{@path}"
                    evt.dataTransfer.dropEffect = "none"
                else
                    evt.dataTransfer.dropEffect = "link"
                    @icon_open()

            enter: (evt) =>

            leave: (evt) =>
                @icon_close()

    move_in: (c_path) ->
        p = c_path.replace("file://", "")
        Desktop.Core.run_command("mv '#{p}' '#{@path}'")


class NormalFile extends DesktopEntry

class DesktopApplet extends Item
