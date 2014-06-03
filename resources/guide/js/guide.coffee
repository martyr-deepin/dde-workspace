
class Guide

    constructor:->
        echo "Guide"
        
        document.body.style.height = screen.height
        document.body.style.width = screen.width
        echo screen.width + "*" + screen.height

        @guide = new PageContainer("guide")
        document.body.appendChild(@guide.element)
        @pages = []

    create_page: (cls_name)->
        cls_name = "Welcome"
        switch cls_name
            when "Welcome"
                DCore.Guide.disable_keyboard()
                DCore.Guide.disable_right_click()
                page = new Welcome(cls_name)
            
            when "Start"
                #DCore.Guide.disable_keyboard()
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
                DCore.Guide.enable_guide_region()
                
                page = new Start(cls_name)
            
            when "LauncherLaunch"
                DCore.Guide.enable_right_click()
                #DCore.Guide.disable_keyboard()
                DCore.Guide.enable_dock_region()
                page = new LauncherLaunch(cls_name)

            when "LauncherCollect"
                DCore.Guide.disable_right_click()
                #DCore.Guide.disable_keyboard()
                DCore.Guide.disable_dock_region()
                page = new LauncherCollect(cls_name)

            when "LauncherAllApps"
                DCore.Guide.disable_right_click()
                #DCore.Guide.disable_keyboard()
                DCore.Guide.disable_dock_region()
                page = new LauncherAllApps(cls_name)
                
            when "LauncherScroll"
                DCore.Guide.disable_right_click()
                #DCore.Guide.disable_keyboard()
                DCore.Guide.disable_dock_region()
                page = new LauncherScroll(cls_name)
                
            when "LauncherSearch"
                DCore.Guide.disable_right_click()
                #DCore.Guide.disable_keyboard()
                DCore.Guide.disable_dock_region()
                page = new LauncherSearch(cls_name)
                
            when "LauncherRightclick"
                DCore.Guide.disable_right_click()
                #DCore.Guide.disable_keyboard()
                DCore.Guide.disable_dock_region()
                page = new LauncherMenu(cls_name)
                
            when "DesktopRichDir"
                DCore.Guide.disable_right_click()
                #DCore.Guide.disable_keyboard()
                DCore.Guide.disable_dock_region()
                page = new DesktopRichDir(cls_name)
                
            when "DesktopRichDirCreated"
                DCore.Guide.disable_right_click()
                #DCore.Guide.disable_keyboard()
                DCore.Guide.disable_dock_region()
                page = new DesktopRichDirCreated(cls_name)
                
            when "DesktopCorner"
                DCore.Guide.disable_right_click()
                #DCore.Guide.disable_keyboard()
                DCore.Guide.disable_dock_region()
                page = new DesktopCorner(cls_name)
                
            when "DesktopZone"
                DCore.Guide.disable_right_click()
                #DCore.Guide.disable_keyboard()
                DCore.Guide.disable_dock_region()
                page = new DesktopZone(cls_name)
                
            when "DssLaunch"
                DCore.Guide.disable_right_click()
                #DCore.Guide.disable_keyboard()
                DCore.Guide.disable_dock_region()
                page = new DssLaunch(cls_name)
                
            when "DssArea"
                DCore.Guide.disable_right_click()
                DCore.Guide.disable_keyboard()
                DCore.Guide.disable_dock_region()
                page = new DssArea(cls_name)
                
            when "End"
                DCore.Guide.disable_right_click()
                DCore.Guide.disable_keyboard()
                DCore.Guide.disable_dock_region()
                page = new End(cls_name)
            
        @guide.add_page(page)

guide = new Guide()
guide.create_page("Start")

