db_conn = openDatabase("test", "0.1", "test widget info database", 10*1024)
db_conn.transaction (tx) ->
    tx.executeSql "CREATE TABLE WidgetInfo (id REAL UNIQUE, x Int, y Int)"


class Widget
    _$: ->
        $("##{@id}")

    get_x: ->
        @_$().position().left

    get_y: ->
        @_$().position().top

    get_width: ->
        @_$().outerWidth()

    get_height: ->
        @_$().outerHeight()

    get_position: ->
        pos = @_$().position()
        [pos.top, pos.left]

    set_position: (x, y) ->
        x = this.get_x() if x == -1
        y = this.get_y() if y == -1
        @_$().position
            of: @_$().parent()
            my: "left top"
            at: "left top"
            offset: "#{x} #{y}"

    set_id: (id) ->
        @id = id

    save_info: ->
        db_conn.transaction (tx) =>
            tx.executeSql(
                "replace into WidgetInfo (id, x, y) values (?, ?, ?)",
                [this.id, this.get_x(), this.get_y()],
                (result) -> 
                (tx, error) -> console.log(error)
            )

    load_info: ->
        db_conn.transaction (tx) =>
            tx.executeSql(
                "select id, x, y from WidgetInfo where id = ?",
                [this.id],
                (tx, r) =>
                    p = r.rows.item(0)
                    this.set_position(p.x, p.y)
                (tx, error) -> console.log("error")
            )
                    


class Item extends Widget 
    constructor: (@name, @icon, @exec) ->
        @itemTemp = "icontemp"
        @itemContainer = "itemContainer"
        @id = DCore.gen_id(@name + @icon + @exec)

    render : ->
        $("##{@itemContainer}").append(
            $("##{@itemTemp}").render
                "class" : "item"
                "id" : @id
                "name" : @name
                "icon" : @icon
                "exec" : @exec
        )
        this._$()
            .draggable
                stop: (event, ui) => this.save_info()
            .dblclick ->
                DCore.run_command $(this)[0].getAttribute('exec')

        this.load_info()


class DesktopEntry extends Item
    
class Folder extends Item

class IconGroup extends Item

render_item = (item) ->
    i = new Item item.name, item.icon, item.exec
    return i.render()

$ ->
    render_item item for item in DCore.get_desktop_items()

    $("#dialog").dialog
        autoOpen: false
        show: "blind"
        hide: "explode"

    $("#opener").click ->
        $("#dialog").dialog "open"
        DCore.make_popup("dialog")
        return false
