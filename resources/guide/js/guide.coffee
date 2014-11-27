class Guide extends Widget
    page_index = 0
    restack_tid = null
    constructor: (@id)->
        super
        @pages = []
        echo "new Guide"
        document.body.appendChild(@element)
        if DEBUG
            @exit_button_create()
        else
            restack_tid = setInterval(->
                DCore.Guide.restack()
            ,150)

    exit_button_create: ->
        exit_button = create_element("botton","",document.body)
        exit_button.innerText = "Exit"
        exit_button.style.position = "absolute"
        exit_button.style.zIndex = 1000
        exit_button.style.top = 10
        exit_button.style.color = "rgb(255,255,255)"
        exit_button.style.right = 150
        exit_button.style.fontSize = 16
        exit_button.addEventListener("click",(e) =>
            e.stopPropagation()
            enableZoneDetect(true)
            DCore.Guide.quit()
        )
    set_size: (info) =>
        @element.style.position = "fixed"
        @element.style.left = info.x
        @element.style.top = info.y
        @element.style.height = info.height
        @element.style.width = info.width

    add_page: (cls) ->
        try
            @element.appendChild(cls.element)
            page_index++
            page = {}
            page.index = page_index
            page.cls = cls
            page.id = cls.id
            @current_page_id = page.id
            @pages.push(page)
        catch error
            echo "[add_page]:error:#{error}"

    remove_page: (cls) ->
        try
            i_target = i for page,i in @pages when page.id is cls.id
            @pages.splice(i_target,1)
            @element.removeChild(cls.element)
        catch error
            echo "[remove_page]:error:#{error}"

    switch_page: (old_page, new_page_cls_name) ->
        echo "switch page from ---#{old_page.id}--- to ----#{new_page_cls_name}----"
        @remove_page(old_page)
        @create_page(new_page_cls_name)

    create_page: (cls_name)->
        if !DEBUG
            DCore.Guide.disable_keyboard()
            DCore.Guide.disable_right_click()
        else
            DCore.Guide.disable_guide_region()
        enableZoneDetect(false)
        echo "create_page #{cls_name}"
        switch cls_name
            when "Welcome"
                page = new Welcome(cls_name)
            when "Start"
                # only guide can get keydown
                #DCore.Guide.disable_keyboard()

                # only guide cannot get keydown event
                #DCore.Guide.enable_keyboard()

                # only guide has left click ,not right_click
                # desktop launcher dock all event disable
                #DCore.Guide.disable_right_click()

                # only guide has left click and right_click
                # desktop  launcher dock all event disable
                #DCore.Guide.enable_right_click()


                # guide all event disable
                # desktop launcher all event enable
                # dock all event disable
                #DCore.Guide.disable_guide_region()

                # guide all event enable
                # desktop launcher dock all event disbable
                #DCore.Guide.enable_guide_region()

                page = new Start(cls_name)
            when "DockMenu"
                page = new DockMenu(cls_name)

            when "LauncherLaunch"
                page = new LauncherLaunch(cls_name)

            when "LauncherSearch"
                page = new LauncherSearch(cls_name)

            when "LauncherIconDrag"
                page = new LauncherIconDrag(cls_name)

            when "LauncherMenu"
                page = new LauncherMenu(cls_name)

            when "DesktopRichDir"
                page = new DesktopRichDir(cls_name)

            when "DesktopRichDirCreated"
                page = new DesktopRichDirCreated(cls_name)

            when "DesktopCornerInfo"
                page = new DesktopCornerInfo(cls_name)

            when "DesktopCornerLeftUp"
                page = new DesktopCornerLeftUp(cls_name)

            when "DesktopCornerLeftDown"
                page = new DesktopCornerLeftDown(cls_name)

            when "DssLaunch"
                page = new DssLaunch(cls_name)

            when "DssShutdown"
                page = new DssShutdown(cls_name)

            when "DesktopCornerRightUp"
                page = new DesktopCornerRightUp(cls_name)
                clearInterval(restack_tid)

            when "DesktopZoneSetting"
                page = new DesktopZoneSetting(cls_name)

            when "End"
                page = new End(cls_name)

            else
                echo "cls_name is #{cls_name}"
        @add_page(page)
