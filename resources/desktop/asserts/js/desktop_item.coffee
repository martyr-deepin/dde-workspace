class Item extends Widget
    constructor: (@name, @icon, @exec, @path) ->
        @id = Desktop.Core.gen_id(@path)
        @itemTemp = "temp_item"
        @itemContainer = "itemContainer"
        init_item_pos(@id)

    render : ->
        item = $("##{@itemTemp}").render
                "class" : "item"
                "id" : @id
                "name" : @name
                "icon" : @icon
                "exec" : @exec
                "path" : @path
        $("##{@itemContainer}").append item

        this._$()
            .dblclick ->
                Desktop.Core.run_command $(this)[0].getAttribute('exec')

class DesktopEntry extends Item
    render : ->
        super.render()
        @_$().drag
            "start": (evt) =>
                #evt.dataTransfer.setData("Text", @id)
                evt.dataTransfer.setData("text/uri-list", "file://#{@path}")
                evt.dataTransfer.effectAllowed = "move"
                evt.dataTransfer.dropEffect = "move"
            "end": (evt) =>
                if evt.dataTransfer.dropEffect == "move"
                    evt.preventDefault()
                    node = evt.originalEvent.target
                    pos = pixel_to_position(evt.originalEvent.x,
                        evt.originalEvent.y)

                    move_to_position(node, pos[0], pos[1])
                else if evt.dataTransfer.dropEffect == "link"
                    node = evt.originalEvent.target
                    node.parentNode.removeChild(node)

    
class Folder extends DesktopEntry
    icon_open: ->
         @_$().find("img")[0].src = "/usr/share/icons/oxygen/48x48/status/folder-open.png"
    icon_close: ->
         @_$().find("img")[0].src = "/usr/share//icons/oxygen/48x48/mimetypes/inode-directory.png"


    render : ->
        super.render()
        @_$().drop
            drop: (evt) =>
                evt.dataTransfer.getData("text/uri-list")
                @icon_close()
                evt.preventDefault()

            over: (evt) =>
                path = evt.dataTransfer.getData("text/uri-list")
                if path == "file://#{@path}"
                    echo "same"
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

create_item = (info) ->
    switch info.type
        when "Entry" then new DesktopEntry info.name, info.icon, info.exec, info.path
        when "File" then new NormalFile info.name, info.icon, info.exec, info.path
        when "Dir" then new Folder info.name, info.icon, info.exec, info.path
        else echo "don't support type"



