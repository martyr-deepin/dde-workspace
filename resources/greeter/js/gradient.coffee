class Gradient extends Widget
    constructor:(@id)->
        super
        echo "new Gradient"
        Angle = (n)->
            return n * Math.PI
        return
        switch @id
            when 1
                @element.style.left = 0
                @element.style.bottom= 0
            when 2
                @element.style.right = 0
                @element.style.top = 0
            when 3
                @element.style.left = "0"
                @element.style.top = "0"
            when 4
                @element.style.right = 0
                @element.style.bottom = 0

        r = 150

        remove_element(myCanvas) if myCanvas
        myCanvas = create_element("canvas","myCanvas",@element)
        myCanvas.id = "myCanvas"
        myCanvas.style.width = r * 2
        myCanvas.style.height = r * 2
        ctx = myCanvas.getContext("2d")
    
        ctx.beginPath()
        ctx.moveTo(0,0)
        ctx.lineTo(r * 1.5,0)
        ctx.lineTo(0,r)
        ctx.lineTo(0,0)
        ctx.closePath()
        ctx.stroke()
        
        #ctx.fillRect(0,0,r,r)
        
        grd = ctx.createLinearGradient(0,0,170,0)
        grd.addColorStop(0,"rgba(255,255,255,0.5)")
        grd.addColorStop(1,"rgba(0,0,0,0.3)")
        
        ctx.fillStyle = grd
        ctx.fill()
                
        @element.style.position = "absolute"
        #myCanvas.rotate(Angle(0.5 * (@id  - 1)))

