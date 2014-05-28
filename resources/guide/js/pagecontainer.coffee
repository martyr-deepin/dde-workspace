
class PageContainer extends Widget
    constructor: (@id)->
        super

    add_page: (page_id) ->
        try
            @element.appendChild(page_id.element)
        catch error
            echo error

    remove_page: (page_id) ->
        try
            @element.removeChild(page_id.element)
        catch error
            echo error

    switch_page: (old_page, new_page) ->
        echo "switch page"

    current_page: ->
        echo "current_page"

