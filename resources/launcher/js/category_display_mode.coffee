class CategoryDisplayMode
    @Mode:
        Icon: 0
        Text: 1

    constructor:(mode)->
        @mode = null
        switch mode
            when CategoryDisplayMode.Mode.Text, CategoryDisplayMode.Mode.Icon
                @mode = mode

    isValid:->
        @mode != null

    toString:->
        switch @mode
            when CategoryDisplayMode.Mode.Text
                return "text"
            when CategoryDisplayMode.Mode.Icon
                return "icon"

        return "unknown"
