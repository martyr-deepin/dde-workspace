last_time = (new Date()).getTime()

m = new DeepinMenu()
i1 = new DeepinMenuItem(1, "Open")
i2 = new DeepinMenuItem(2, "Delete")
i3 = new DeepinMenuItem(3, "Rename")
i4 = new DeepinMenuItem(4, "Properties")
m.appendItem(i1)
m.appendItem(i2)
m.appendItem(i3)
m.appendItem(i4)

shorten_text = (str, n) ->
    r = /[^\x00-\xff]/g
    if str.replace(r, "mm").length <= n
        return str

    mid = Math.floor(n / 2)
    n = n - 3
    for i in [mid..(str.length - 1)]
        if str.substr(0, i).replace(r, "mm").length >= n
            return str.substr(0, i) + "..."

    return str

class Item extends Widget
    constructor: (@name, @icon, @exec, @path) ->
        @id = @path
        super

        el = @element
        info = {x:0, y:0, width:1, height:1}

        #el.setAttribute("tabindex", 0)
        el.draggable = true
        el.innerHTML = "
        <img draggable=false src=#{@icon} />
        <div class=item_name>#{shorten_text(@name, 20)}</div>
        "

        # search the div for store the name
        @item_name = sub_item for sub_item in el.childNodes when sub_item.className == "item_name"

        @element.addEventListener('click', (e)->
            echo (e)
            n = (new Date()).getTime()
            echo "#{n - last_time}"
            if this.className.search(/item_selected/i) > -1
                if n - last_time > 200
                    this.className = this.className.replace(" item_selected", "")
            else
                this.className += " item_selected"
            last_time = n
        )

        @element.addEventListener('dblclick', ->
            DCore.run_command exec
        )
        @element.addEventListener('itemselected', (env) ->
            echo "menu clicked:id=#{env.id} title=#{env.title}"
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
    constructor : ->
        super

        @div_pop = null
        @element.addEventListener('click', =>
            @show_pop_block()
        )

    show_pop_block : ->
        @div_background = document.createElement("div")
        @div_background.setAttribute("id", "pop_background")
        document.body.appendChild(@div_background)
        @div_background.addEventListener('click', => @hide_pop_block())
        @div_pop = document.createElement("div")
        @div_pop.setAttribute("id", "pop_grid")
        document.body.appendChild(@div_pop)
        items = DCore.Desktop.get_items_by_dir(@element.id)
        str = ""
        str += "<li><img src=\"#{s.Icon}\"><div>#{shorten_text(s.Name, 20)}</div></li>" for s in items
        @div_pop.innerHTML = "<ul>#{str}</ul>"

        if items.length <= 3
            col = items.length
        else if items.length <= 8
            col = 4
        else if items.length <= 15
            col = 5
        else
            col = 6
        @div_pop.style.width = "#{col * i_width + 20}px"

        n = Math.ceil(items.length / col)
        if n > 4 then n = 4
        n = n * i_height + 20
        if @element.offsetTop > n
            @div_pop.style.top = "#{@element.offsetTop - n}px"
        else
            @div_pop.style.top = "#{@element.offsetTop + @element.offsetHeight + 20}px"

        n = (col * i_width) / 2 + 10
        p = @element.offsetLeft + @element.offsetWidth / 2
        if p < n
            @div_pop.style.left = "0"
        else if p + n > s_width
            @div_pop.style.left = "#{s_width - 2 * n}px"
        else
            @div_pop.style.left = "#{p - n}px"

    hide_pop_block : ->
        @div_background.parentElement.removeChild(@div_background)
        @div_pop.parentElement.removeChild(@div_pop)
        delete @div_background
        delete @div_pop

    init_drop: =>
        $(@element).drop
            drop: (evt) =>
                file = decodeURI(evt.dataTransfer.getData("text/uri-list"))
                evt.preventDefault()
                #@icon_close()
                @move_in(file)

            over: (evt) =>
                evt.preventDefault()
                path = decodeURI(evt.dataTransfer.getData("text/uri-list"))
                if path == "file://#{@path}"
                    evt.dataTransfer.dropEffect = "none"
                else
                    evt.dataTransfer.dropEffect = "link"
                    #@icon_open()

            enter: (evt) =>

            leave: (evt) =>
                #@icon_close()

    move_in: (c_path) ->
        echo "#{c_path}  #{@path}"
        p = c_path.replace("file://", "")
        DCore.run_command("mv '#{p}' '#{@path}'")


class NormalFile extends DesktopEntry

class DesktopApplet extends Item
