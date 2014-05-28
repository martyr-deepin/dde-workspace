
class Guide extends Widget

    constructor:->
        super
        echo "Guide"
        #document.body.style.height = window.innerHeight
        #document.body.style.width = window.innerWidth
        echo window.innerHeight + "," + window.innerWidth
        document.body.appendChild(@element)



new Guide()
