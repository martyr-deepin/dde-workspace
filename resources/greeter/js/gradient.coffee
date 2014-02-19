class Gradient extends Widget
    constructor:(@id)->
        super
        echo "new Gradient"
        return
        Angle = (n)->
            return n * Math.PI
        #return
        switch @id
            when 1
                @element.style.left = "0"
                @element.style.top = "0"
            when 2
                @element.style.right = 0
                @element.style.top = 0
            when 3
                @element.style.right = 0
                @element.style.bottom = 0
            when 4
                @element.style.left = 0
                @element.style.bottom= 0

        r = 200
        c = 10
        
        remove_element(myCanvas) if myCanvas
        myCanvas = create_element("canvas","myCanvas",@element)
        myCanvas.id = "myCanvas"
        myCanvas.style.width = r
        myCanvas.style.height = r * WindowWidth / WindowHeight
        ctx = myCanvas.getContext("2d")
        
        grd = ctx.createRadialGradient(250,250,50,250,250,600)
        grd.addColorStop(0,"rgba(255,255,255,0.5)")
        grd.addColorStop(1,"rgba(0,0,0,0.3)")
        ctx.fillStyle = grd
    
        ctx.beginPath()
        ctx.moveTo(0,0)
        ctx.lineTo(r,0)
        ctx.quadraticCurveTo(c,c,0,r)
        ctx.closePath()
        ctx.fill()
                
        @element.style.position = "absolute"

