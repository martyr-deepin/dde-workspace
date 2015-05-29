RegExp.escape = (text)->
    text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, "\\$&")

Storage::setObject = (key, value) ->
    @setItem(key, JSON.stringify(value))

Storage::getObject = (key) ->
    JSON.parse(@getItem(key))

String::startsWith = (pre) ->
    this.indexOf(pre) == 0

String::endsWith = (suffix)->
    return this.indexOf(suffix, this.length - suffix.length) != -1

String::args = ->
    o = this
    len = arguments.length
    for i in [1..len]
        o = o.replace(new RegExp("%" + i, "g"), "#{arguments[i - 1]}")

    return o

String::isPath = ->
    @indexOf("/") != -1

String::isDataURLImage = ->
    @match(/^data:image\/.+(;base64)?,/)

String::addSlashes = ->
    @replace(/[\\"']/g, '\\$&').replace(/\u0000/g, '\\0')

Array.prototype.remove = (el)->
    i = this.indexOf(el)
    if i != -1
        this.splice(this.indexOf(el), 1)[0]

# if typeof Object.clone != 'function'
#     Object::clone = ->
#         o = {}
#         for i of @
#             if @.hasOwnProperty(i)
#                 o[i] = @[i]
#         o
#
# Array::clone = (deep)->
#     deep = deep || false
#     if deep && typeof @[0] == 'object' && @[0].clone?
#         res = []
#         for i of @
#             res.push(i.clone())
#         res
#     else
#         @.slice(0)

