class SortMethod
    @Method:
        ByName:0
        ByCategory:1
        ByTimeInstalled:2
        ByFrequency:3

    constructor:(method)->
        @method = null
        switch method
            when SortMethod.Method.ByName, SortMethod.Method.ByCategory, SortMethod.Method.ByTimeInstalled, SortMethod.Method.ByFrequency
                @method = method

    isValid:->
        @method != null

    toString:->
        switch @method
            when SortMethod.Method.ByName
                return "name"
            when SortMethod.Method.ByCategory
                return "category"
            when SortMethod.Method.ByTimeInstalled
                return "date"
            when SortMethod.Method.ByFrequency
                return "frequency"
        return "unknown"


sortByNameCompare = (lhs, rhs)->
        lItem = Widget.look_up(lhs)
        rItem = Widget.look_up(rhs)

        if lItem.name > rItem.name
            return 1
        if lItem.name < rItem.name
            return -1
        return 0

sortByName = (apps)->
    apps.sort(sortByNameCompare)

sortByFrequency = (apps, frequency)->
    apps.sort((lhs, rhs)->
        if frequency[lhs] > frequency[rhs]
            return -1

        if frequency[lhs] < frequency[rhs]
            return 1

        sortByNameCompare(lhs, rhs)
    )

sortByTimeInstalled = (apps, timeInstalled)->
    apps.sort((lhs, rhs)->
        if timeInstalled[lhs] > timeInstalled[rhs]
            return -1

        if timeInstalled[lhs] < timeInstalled[rhs]
            return 1

        sortByNameCompare(lhs, rhs)
    )
