class Guide extends Widget
    page_index = 0
    
    constructor: (@id)->
        super
        @pages = []
        echo "new Guide"
        
        document.body.style.height = screen.height
        document.body.style.width = screen.width
        echo screen.width + "*" + screen.height
        document.body.appendChild(@element)

    add_page: (cls) ->
        try
            @element.appendChild(cls.element)
            page_index++
            page = {}
            page.index = page_index
            page.cls = cls
            page.id = cls.id
            #echo page
            @pages.push(page)
        catch error
            echo error

    remove_page: (cls) ->
        try
            i_target = i for page,i in @pages when page.id is cls.id
            @pages.splice(i_target,1)
            @element.removeChild(cls.element)
        catch error
            echo "#{error}"


    
    switch_page: (old_page, new_page_cls_name) ->
        echo "switch page from ---#{old_page.id}--- to ----#{new_page_cls_name}----"
        @remove_page(old_page)
        @create_page(new_page_cls_name)
    
    create_page: (cls_name)->
        DCore.Guide.disable_keyboard()
        DCore.Guide.disable_right_click()
        enableZoneDetect(false)
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
            
            when "LauncherLaunch"
                page = new LauncherLaunch(cls_name)
                enableZoneDetect(true)

            when "LauncherCollect"
                page = new LauncherCollect(cls_name)

            when "LauncherAllApps"
                page = new LauncherAllApps(cls_name)
                
            when "LauncherScroll"
                page = new LauncherScroll(cls_name)
                
            when "LauncherSearch"
                page = new LauncherSearch(cls_name)
                
            when "LauncherRightclick"
                page = new LauncherRightclick(cls_name)
                
            when "LauncherMenu"
                DCore.Guide.enable_right_click()
                page = new LauncherMenu(cls_name)
                
            when "DesktopRichDir"
                page = new DesktopRichDir(cls_name)
                
            when "DesktopRichDirCreated"
                page = new DesktopRichDirCreated(cls_name)
                
            when "DesktopCorner"
                page = new DesktopCorner(cls_name)
                enableZoneDetect(true)
                
            when "DesktopZone"
                page = new DesktopZone(cls_name)
                
            when "DssLaunch"
                page = new DssLaunch(cls_name)
                
            when "DssArea"
                DCore.Guide.disable_guide_region()
                page = new DssArea(cls_name)
                
            when "End"
                DCore.Guide.enable_guide_region()
                page = new End(cls_name)
            else
                echo "cls_name is #{cls_name}"
        @add_page(page)

guide = null
guide = new Guide()
