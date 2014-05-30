
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
        #welcome = new Welcome("welcome_page")
        #@pages.push(welcome)
        #guide.add_page(welcome)

        #start_page = new Start("start_page")
        #guide.add_page(start_page)

        #launcherLaunch_page = new LauncherLaunch("launcherLaunch_page")
        #guide.add_page(launcherLaunch_page)

        #launcherCollect_page = new LauncherCollect("launcherCollect_page")
        #guide.add_page(launcherCollect_page)

        

guide = new Guide()
guide.create_page()

