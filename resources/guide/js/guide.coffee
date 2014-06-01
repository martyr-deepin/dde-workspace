
class Guide

    constructor:->
        echo "Guide"
        
        document.body.style.height = screen.height
        document.body.style.width = screen.width
        echo screen.width + "*" + screen.height

        @guide = new PageContainer("guide")
        document.body.appendChild(@guide.element)
        @pages = []

    create_page: ->
        #@pages.push(welcome)
        #welcome = new Welcome("welcome_page")
        #@guide.add_page(welcome)

        start = new Start("start_page")
        @guide.add_page(start)

        #launcherLaunch = new LauncherLaunch("launcherLaunch_page")
        #@guide.add_page(launcherLaunch)

        #launcherCollect = new LauncherCollect("launcherCollect_page")
        #@guide.add_page(launcherCollect)

        #LauncherAllApps = new LauncherAllApps("LauncherAllApps_page")
        #@guide.add_page(LauncherAllApps)
        
        #LauncherScroll = new LauncherScroll("LauncherScroll_page")
        #@guide.add_page(LauncherScroll)
        
        #LauncherSearch = new LauncherSearch("LauncherSearch_page")
        #@guide.add_page(LauncherSearch)
        
        #LauncherRightclick = new LauncherRightclick("LauncherRightclick_page")
        #@guide.add_page(LauncherRightclick)
        
        #LauncherMenu = new LauncherMenu("LauncherMenu_page")
        #@guide.add_page(LauncherMenu)
        
        #DesktopRichDir = new DesktopRichDir("DesktopRichDir_page")
        #@guide.add_page(DesktopRichDir)
        
        #DesktopRichDirCreated = new DesktopRichDirCreated("DesktopRichDirCreated_page")
        #@guide.add_page(DesktopRichDirCreated)
        
        #DesktopCorner = new DesktopCorner("corner_page")
        #@guide.add_page(DesktopCorner)
        
        #DesktopZone = new DesktopZone("zone_page")
        #@guide.add_page(DesktopZone)
        
        #DssLaunch = new DssLaunch("dssLaunch_page")
        #@guide.add_page(DssLaunch)
        
        #DssArea = new DssArea("dssarea_page")
        #@guide.add_page(DssArea)
        
        #End = new End("end_page")
        #@guide.add_page(End)
        

guide = new Guide()
guide.create_page()

