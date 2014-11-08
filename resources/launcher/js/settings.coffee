class Setting
    constructor:(@core)->
        try
            @categoryDisplayMode = new CategoryDisplayMode(@core.GetCategoryDisplayMode_sync())
            @sortMethod = new SortMethod(@core.GetSortMethod_sync())
        catch e
            console.error("get settings failed: #{e}")
            DCore.Launcher.quit()

    listenCategoryDisplayModeChanged:(fn)->
        @core.connect("CategoryDisplayModeChanged", (mode)=>
            newCategoryDisplayMode = new CategoryDisplayMode(mode)
            if newCategoryDisplayMode.isValid()
                @categoryDisplayMode = newCategoryDisplayMode
                fn(mode)
        )

    listenSortMethodChanged:(fn)->
        @core.connect("SortMethodChanged", (method)=>
            newSortMethod = new SortMethod(method)
            if newSortMethod.isValid()
                @sortMethod = newSortMethod
                fn(method)
        )

    getCategoryDisplayMode:->
        @categoryDisplayMode.mode

    setCategoryDisplayMode:(newMode)->
        @core.SetCategoryDisplayMode(newMode)

    getSortMethod:->
        @sortMethod.method

    setSortMethod:(newMethod)->
        @core.SetSortMethod(newMethod)
