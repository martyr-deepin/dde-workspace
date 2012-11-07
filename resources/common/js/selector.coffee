$ = (q, o) ->
    return [] if typeof(q) != 'string' or q == ''
    switch q.charAt(0)
        when '#' then return document.getElementById(q.substr(1))
        when '.' then return document.querySelectorAll(q.substr(1))
        else
            return document.getElementByTagName(q)
    

