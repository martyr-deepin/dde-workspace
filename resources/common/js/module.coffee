class Module
    moduleKeywords = ['extended', 'included']
    @extended : (obj) ->
        for key, value of obj when key not in moduleKeywords
            @[key] = value
        obj.extended?.apply(@)
        this

    @included: (obj, parms) ->
        for key, value of obj when key not in moduleKeywords
            @::[key] = value
        obj.included?.apply(@)
        obj.__init__?.call(@, parms)
