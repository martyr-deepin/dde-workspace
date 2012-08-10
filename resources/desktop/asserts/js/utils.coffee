Storage.prototype.setObject = (key, value) ->
    @setItem(key, JSON.stringify(value))

Storage.prototype.getObject = (key) ->
    JSON.parse(@getItem(key))

echo = (log) ->
    console.log log

assert = (value, msg) ->
    if not value
        throw new Error(msg)
