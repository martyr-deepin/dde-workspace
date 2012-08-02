class Item extends Widget
    @included Recordable, ["id", "x", "y"]

    constructor: (@name, @icon, @exec) ->
        @id = Desktop.Core.gen_id(@name + @icon + @exec)
        @itemTemp = "temp_item"
        @itemContainer = "itemContainer"
        @load()

    render : ->
        item = $("##{@itemTemp}").render
                "class" : "item"
                "id" : @id
                "name" : @name
                "icon" : @icon
                "exec" : @exec
        $("##{@itemContainer}").append item

        this._$()
            .dblclick ->
                Desktop.Core.run_command $(this)[0].getAttribute('exec')


class DesktopEntry extends Item
    render : ->
        super.render()
        @_$().drag
            "start": (evt) ->
                evt.dataTransfer.setData("text/x-text", "test")
                evt.dataTransfer.setData("id", this.id)
                evt.dataTransfer.effectAllowed = "move link"
                evt.dataTransfer.dropEffect = "move"
            "end": (evt) =>
                if evt.dataTransfer.dropEffect == "move"
                    evt.preventDefault()
                    node = evt.originalEvent.target
                    node.style.position = "fixed"
                    node.style.left = evt.originalEvent.x
                    node.style.top = evt.originalEvent.y
                    evt.dataTransfer.dropEffect = "move"
                    this.save()
                else if evt.dataTransfer.dropEffect == "link"
                    node = evt.originalEvent.target
                    node.parentNode.removeChild(node)

    
class Folder extends Item

class NormalFile extends Item

class DesktopApplet extends Item
