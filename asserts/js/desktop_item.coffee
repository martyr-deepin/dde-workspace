class Item extends Widget
    @included Recordable, ["id", "x", "y"]

    constructor: (@name, @icon, @exec) ->
        @id = Desktop.Core.gen_id(@name + @icon + @exec)
        @itemTemp = "icontemp"
        @itemContainer = "itemContainer"
        @load()

    render : ->
        $("##{@itemContainer}").append(
            $("##{@itemTemp}").render
                "class" : "item"
                "id" : @id
                "name" : @name
                "icon" : @icon
                "exec" : @exec
        )
        #document.querySelector("#itemContainer").addEventListener('drop', 
            #(e) ->
                #echo "dropeed"
        #)

        #for item in document.querySelectorAll(".item")
            #item.addEventListener('dragstart', (e) ->
                ##echo e.dataTransfer.effectAllowed, false)
                #)

        this._$()
            .draggable
                stop: (event, ui) =>
                    this.save()
            .dblclick ->
                Desktop.Core.run_command $(this)[0].getAttribute('exec')


class DesktopEntry extends Item
    
class Folder extends Item

class IconGroup extends Item
