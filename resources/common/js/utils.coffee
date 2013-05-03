#Copyright (c) 2011 ~ 2012 Deepin, Inc.
#              2011 ~ 2012 snyh
#
#Author:      snyh <snyh@snyh.org>
#Maintainer:  snyh <snyh@snyh.org>
#
#This program is free software; you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation; either version 3 of the License, or
#(at your option) any later version.
#
#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program; if not, see <http://www.gnu.org/licenses/>.

Storage.prototype.setObject = (key, value) ->
    @setItem(key, JSON.stringify(value))

Storage.prototype.getObject = (key) ->
    JSON.parse(@getItem(key))

String.prototype.endsWith = (suffix)->
    return this.indexOf(suffix, this.length - suffix.length) != -1

Array.prototype.remove = (el)->
    i = this.indexOf(el)
    if i != -1
        this.splice(this.indexOf(el), 1)[0]

echo = (log) ->
    console.log log

assert = (value, msg) ->
    if not value
        throw new Error(msg)

_ = (s)->
    DCore.gettext(s)


build_menu = (info) ->
    m = new DeepinMenu
    for v in info
        if v.length == 0  #separater item
            i = new DeepinMenuItem(2, 0, 0, 0)
        else if typeof v[0] == "number"  #normal item
            i = new DeepinMenuItem(0, v[0], v[1], null)
            if v.length > 2 and v[2] == false
                i.enabled = false
            else
                i.enabled = true
        else  #sub menu item
            sm = build_menu(v[1])
            i = new DeepinMenuItem(1, 0, v[0], sm)
        m.appendItem(i)
    return m

get_page_xy = (el, x, y) ->
    p = webkitConvertPointFromNodeToPage(el, new WebKitPoint(x, y))

find_drag_target = (el)->
    p = el
    if p.draggable
        return p
    while p = el.parentNode
        if p.draggable
            return p
    return null

swap_element = (c1, c2) ->
    if c1.parentNode == c2.parentNode
        tmp = document.createElement('div')
        c1.parentNode.insertBefore(tmp, c1)
        c2.parentNode.insertBefore(c1, c2)
        tmp.parentNode.insertBefore(c2, tmp)
        tmp.parentNode.removeChild(tmp)

#disable default body drop event
document.body.ondrop = (e) -> e.preventDefault()

run_post = (f, self)->
    f2 = f.bind(self or this)
    setTimeout(f2, 0)

create_element = (type, clss, parent)->
    el = document.createElement(type)
    el.setAttribute("class", clss) if clss
    if parent
        parent.appendChild(el)
    return el

create_img = (clss, src, parent)->
    el = create_element('img', clss, parent)
    el.src = src
    el.draggable = false
    return el

calc_text_size = (txt, width)->
    tmp = create_element('div', 'hidden_calc_text', document.body)
    tmp.innerText = txt
    tmp.style.width = "#{width}px"
    h = tmp.clientHeight
    document.body.removeChild(tmp)
    return h

clamp = (value, min, max)->
    return min if value < min
    return max if value > max
    return value

get_function_name = ->
    return "AnymouseFunction" if not arguments.caller
    /function (.*?)\(/.exec(arguments.caller.toString())[1]


DEEPIN_ITEM_ID = "deepin-item-id"
dnd_is_desktop = (e)->
    return e.dataTransfer.getData("text/uri-list").trim().endsWith(".desktop")
dnd_is_deepin_item = (e)->
    if e.dataTransfer.getData(DEEPIN_ITEM_ID)
        return true
    else
        return false
dnd_is_file = (e)->
    return e.dataTransfer.getData("text/uri-list").length != 0

ajax = (url, method, callback, asyn=true) ->
    xhr = new XMLHttpRequest()
    xhr.open(method, url, asyn)
    xhr.send(null)
    xhr.onreadystatechange = ->
        if (xhr.readyState == 4 and xhr.status == 200)
            callback?(xhr)


class Loader
    constructor : ->
        window.loader = new Object
        @loader = window.loader
        @syncjs = []
        @asyncjs = []
        @css = []
        @syncjs.has = @asyncjs.has = @css.has = (f) ->
            for i in this
                if f == this[i].src
                    return true
                else
                    return false

    addjs : (path, sync, callback, args) ->
        js = null
        if sync
            js = @syncjs
        else
            js = @asyncjs
        if !js.has(path)
            js.push('src' : path, 'callback' : callback, 'args' : args)
        return this

    addcss : (path) ->
        if !@css.has(path)
            @css.push('src' : path)
        return this

    load : ->
        @_loadcss()
        @_loadsyncjs()

    _loadcss : ->
        head = document.getElementsByTagName('head')[0]
        for i in @css
            ele = document.createElement('link')
            ele.type = 'text/css'
            ele.rel = 'stylesheet'
            ele.href = i.src
            head.appendChild(ele)
        return

    _loadjs : (object, parent, func) ->
        fs = []
        js = document.createElement('script')
        js.type = 'text/javascript'
        if typeof object.callback == 'function'
            fs.push(object.callback)
        if typeof func == 'function'
            fs.push(func)
        if fs.length > 0
            @_onload(fs, object.args, js)
        js.src = object.src
        parent.appendChild(js)

    _loadsyncjs : =>
        if @syncjs.length > 0
            head = document.getElementsByTagName('head')[0]
            js = @syncjs.shift()
            @_loadjs(js, head, @_loadsyncjs)
        else
            @_loadasyncjs()

    _loadasyncjs : ->
        head = document.getElementsByTagName('head')[0]
        for i in @asyncjs
            @_loadjs(asyncjs[i], head)
        @asyncjs = []
    
    _onload : (func, arg, obj) ->
        if obj
            if typeof func == 'function'
                func = [func]
            if obj.readyState
                obj.onreadystatechange = ->
                    if obj.readyState == 'loaded' || obj.readyState == 'complete'
                        obj.onreadystatechange == null
                        for f in func
                            f(arg)
            else
                obj.onload = ->
                    for f in func
                        f(arg)
        return


