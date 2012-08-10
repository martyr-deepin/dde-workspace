class Item extends Widget
    constructor: (@name, @icon, @exec, @path) ->
        @id = @path #Desktop.Core.gen_id(@path)
        super

        el = @element
        info = {x:0, y:0, width:1, height:1}
        move_to_anywhere(this)

        el.draggable = true
        el.innerHTML = "
        <img draggable=false src=#{@icon}>
            <div class=item_name>#{@name}</div>
        </img>
        "

        @element.addEventListener('dblclick', ->
                Desktop.Core.run_command exec
        )
        @init_drag?()
        @init_drop?()

    destroy: ->
        info = load_position(this)
        super
        clear_occupy(info)


class DesktopEntry extends Item
    init_drag: ->
        el = @element
        el.addEventListener('dragstart', (evt) =>
                #evt.dataTransfer.setData("Text", @id)
                evt.dataTransfer.setData("text/uri-list", "file://#{@path}")
                evt.dataTransfer.effectAllowed = "move"
                evt.dataTransfer.dropEffect = "move"
        )
        el.addEventListener('dragend', (evt) =>
                if evt.dataTransfer.dropEffect == "move"
                    evt.preventDefault()
                    node = evt.target
                    pos = pixel_to_position(evt.x,
                        evt.y)

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
         @_$().find("img")[0].src = "/usr/share/icons/oxygen/48x48/status/folder-open.png"
    icon_close: ->
         @_$().find("img")[0].src = "/usr/share//icons/oxygen/48x48/mimetypes/inode-directory.png"


    init_drop1: ->
        @_$().drop
            drop: (evt) =>
                evt.dataTransfer.getData("text/uri-list")
                @icon_close()
                evt.preventDefault()

            over: (evt) =>
                path = evt.dataTransfer.getData("text/uri-list")
                if path == "file://#{@path}"
                    evt.dataTransfer.dropEffect = "none"
                    evt.preventDefault()
                else
                    evt.dataTransfer.dropEffect = "link"
                    evt.preventDefault()
                @icon_open()
                echo "over"

            enter: (evt) =>
                echo @path
                echo "enter"

            leave: (evt) =>
                @icon_close()


class NormalFile extends DesktopEntry

class DesktopApplet extends Item


$.contextMenu({
    selector: ".Folder"
    callback: (key, opt) ->
        switch key
            when "reload" then location.reload()
            when "sort" then sort_item()
            when "dele" then echo opt
            when "preview" then echo "preview"
    items: {
        "sort": {name: "OpenFolder"}
        "sepl":  "--------------"
        "property": {name: "Property"}
    }
})

$.contextMenu({
    selector: ".DesktopEntry, .NormalFile, .Folder"
    callback: (key, opt) ->
        switch key
            when "reload" then location.reload()
            when "sort" then sort_item()
            when "dele" then echo opt
            when "preview" then echo "preview"
    items: {
        "preview": {name: "Preview"}
        "dele": {name: "Delete"}
        "sort": {name: "Sort Item"}
        "sepl":  "-----DeskEntry---------",
        "reload": {name: "Reload"}
    }
})
