class Item extends Widget
    constructor: (@name, @icon, @exec, @path) ->
        @id = @path
        super

        el = @element
        info = {x:0, y:0, width:1, height:1}
        move_to_anywhere(this)

        el.setAttribute("tabindex", 0)
        el.draggable = true
        el.innerHTML = "
        <img draggable=false src=#{@icon}>
            <div contenteditable=true class=item_name>#{@name}</div>
        </img>
        "

        @element.addEventListener('dblclick', ->
                Desktop.Core.run_command exec
        )
        @init_drag?()
        @init_drop?()
        #@init_keypress?()

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
                evt.dataTransfer.effectAllowed = "all"
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
        $(@element).find("img")[0].src = "/usr/share/icons/oxygen/48x48/status/folder-open.png"
    icon_close: ->
        $(@element).find("img")[0].src = "/usr/share//icons/oxygen/48x48/mimetypes/inode-directory.png"


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


$.contextMenu({
    selector: "body"
    callback: (key, opt) ->
        switch(key)
            when "cbg" then Desktop.Core.run_command("gnome-control-center background")
            when "reload" then location.reload()
            when "sort1" then sort_item_by_time()
            when "sort2" then sort_item_by_type()
            when "sort3" then sort_item_by_name()
            else echo "Nothing"

    items: {
        "cfile": {name:"Create File"}
        "cdir": {name:"Create Directory"}
        "sepl1" : "----------"
        "reload": {name: "*Reload"}
        "sepl2" : "----------"
        "sort1": {name: "Sort By Time"}
        "sort2": {name: "Sort By Type"}
        "sort3": {name: "Sort By Name"}
        "sepl3" : "----------"
        "cbg": {name: "*ChangeBackground"}
    }
})


$.contextMenu({
    selector: ".DesktopEntry, .NormalFile, .Folder"
    callback: (key, opt) ->
        switch key
            when "reload" then location.reload()
            when "del"
                path = opt.$trigger[0].id
                Desktop.Core.run_command("rm -rf -- '#{path}'")
                
            when "preview" then echo "preview"
    items: {
        "preve": {name: "Preview"}
        "sort": {name: "Open"}
        "rename": {name: "Rename"}
        "del": {name: "*Delete"}
        "sepl":  "--------------"
        "property": {name: "Property"}
    }
})
