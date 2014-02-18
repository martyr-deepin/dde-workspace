class Gradient extends Widget
    constructor:(@id)->
        super
        echo "new Gradient"

        remove_element(myCanvas) if myCanvas
        myCanvas = create_element("canvas","myCanvas",@element)
        myCanvas.id = "myCanvas"
        x0 = 0
        y0 = 0
        width = 100
        height = 100
        myCanvas.style.width = width * 2
        myCanvas.style.height = height * 2
        ctx = myCanvas.getContext("2d")
    
        grd=ctx.createLinearGradient(0,0,170,0)
        grd.addColorStop(0,"black")
        grd.addColorStop(1,"white")

        
        Angle = (n)->
            return n * Math.PI
        
        @element.style.position = "absolute"
        switch @id
            when 1
                @element.style.left = 0
                @element.style.top = 0
                ctx.arc(0,0,100,Angle(0),Angle(0.5))
            when 2
                @element.style.right = 0
                @element.style.top = 0
                ctx.arc(WindowWidth,0,100,Angle(0.5),Angle(1))
            when 3
                @element.style.left = 0
                @element.style.bottom= 0
                ctx.arc(WindowWidth,WindowHeight,100,Angle(1),Angle(1.5))
            when 4
                @element.style.right = 0
                @element.style.bottom = 0
                ctx.arc(0,WindowHeight,100,Angle(1.5),Angle(0))

        ctx.fillStyle=grd
        ctx.fill()
