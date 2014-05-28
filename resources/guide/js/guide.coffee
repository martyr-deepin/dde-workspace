 


class Guide

    constructor:->
        echo "Guide"
        
        document.body.style.height = screen.height
        document.body.style.width = screen.width
        echo screen.width + "*" + screen.height

        guide = new PageContainer("guide")
        document.body.appendChild(guide.element)

        welcome = new Welcome("welcome")
        guide.add_page(welcome)




new Guide()
