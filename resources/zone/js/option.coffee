class Option extends Widget
    constructor(@id):->
        echo "Option:#{@id}"
        @opt = []
        @opt_div = []

    insert:(opt)->
        @opt.push(opt)

    opt_build:->
        for opt,i in @opt
            @opt_div[i] = create_element("div","opt_#{i}",@element)
            @opt_div[i].textContent = opt
