class SettingMenu
    constructor:(@switcher, @setting)->
        @element = create_element(tag:"ul", document.body)
        @element.innerHTML = "" +
         "<li data-sort-method=0>%1</li>".args(_("By name")) +
         "<li data-sort-method=1 data-category-display-mode=0>%1</li>".args(_("By category (icon)")) +
         "<li data-sort-method=1 data-category-display-mode=1>%1</li>".args(_("By category (text)")) +
         "<li data-sort-method=2>%1</li>".args(_("By time installed")) +
         "<li data-sort-method=3>%1</li>".args(_("By frequency"))
        @selected = null
        @element.addEventListener("click", (e)=>
            e.stopPropagation()
            e.preventDefault()
            if e.target.tagName == "UL"
                return
            t = e.target
            sortMethod = +t.dataset.sortMethod
            categoryDisplayMode = +t.dataset.categoryDisplayMode
            @setting.setSortMethod(sortMethod)
            if not isNaN(categoryDisplayMode)
                @setting.setCategoryDisplayMode(categoryDisplayMode)
            @setSelected(sortMethod, categoryDisplayMode)
            selector.clean()
            switcher.hideShadow()
            categoryBar.normal()
        )

    setSelected:(sortMethod, categoryDisplayMode)=>
        @selected?.classList.remove("setting")
        switch sortMethod
            when SortMethod.Method.ByName
                @selected = @element.children[0]
            when SortMethod.Method.ByCategory
                if categoryDisplayMode == CategoryDisplayMode.Mode.Icon
                    @selected = @element.children[1]
                else
                    @selected = @element.children[2]
            when SortMethod.Method.ByTimeInstalled
                @selected = @element.children[3]
            when SortMethod.Method.ByFrequency
                @selected = @element.children[4]

        @selected?.classList.add("setting")
        @switcher.changeSetting(sortMethod, categoryDisplayMode)
