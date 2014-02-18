class Gradient extends Widget
    constructor:(@id)->
        super
        echo "new Gradient"
        Angle = (n)->
            return n * Math.PI
        
        r = 100


        remove_element(myCanvas) if myCanvas
        myCanvas = create_element("canvas","myCanvas",@element)
        myCanvas.id = "myCanvas"
        myCanvas.style.width = r
        myCanvas.style.height = r
        ctx = myCanvas.getContext("2d")
    
        grd = ctx.createLinearGradient(0,0,170,0)
        grd.addColorStop(0,"rgba(255,255,255,0.2)")
        grd.addColorStop(1,"rgba(0,0,0,0.2)")
        
        ctx.beginPath()
        ctx.moveTo(0,0)
        ctx.lineTo(r,0)
        ctx.closePath()
        ctx.stroke()
        ctx.beginPath()
        ctx.arc(r,r,r,1*Math.PI,1.5*Math.PI)
        ctx.stroke()
        ctx.beginPath()
        ctx.moveTo(0,0)
        ctx.lineTo(0,r)
        ctx.closePath()
        ctx.stroke()
        
        ctx.fillStyle = grd
        ctx.fill()
                
        @element.style.position = "absolute"
        switch @id
            when 1
                @element.style.left = 0
                @element.style.top = 0
            when 2
                @element.style.right = 0
                @element.style.top = 0
            when 3
                @element.style.left = 0
                @element.style.bottom= 0
            when 4
                @element.style.right = 0
                @element.style.bottom = 0

