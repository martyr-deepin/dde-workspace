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


gridScrollCallback = (e)->
    offset = 0
    cid = -2
    l = this.childNodes.length
    scrollTop = this.scrollTop
    for i in [0...l]
        if this.childNodes[i].style.display == 'none'
            continue
        candidateId = this.childNodes[i].id
        if scrollTop - offset < 0
            # console.log "less #{id} #{$("##{id}").firstChild.firstChild.textContent}"
            $("#grid").style.webkitMaskImage = MASK_TOP_BOTTOM
            categoryBar.focusCategory(cid.substr(Category.PREFIX.length))
            break
        else if scrollTop - offset == 0
            cid = this.childNodes[i].id
            # console.log "equal #{id} #{$("##{id}").firstChild.firstChild.textContent}"
            if cid == "c-2"
                this.style.webkitMask = "none"
            else
                this.style.webkitMask = ""
            categoryBar.focusCategory(cid.substr(Category.PREFIX.length))
            break
        else
            cid = candidateId
            offset += this.childNodes[i].clientHeight + CATEGORY_LIST_ITEM_MARGIN

    return


grid.addEventListener("mousewheel", (e)->
    gridOffset += e.wheelDeltaY / 2
    offset = grid.clientHeight - grid.firstElementChild.clientHeight
    if gridOffset < offset
        gridOffset = offset
    else if gridOffset > 0
        gridOffset = 0
    warp = grid.firstElementChild
    old = warp.style.webkitTransition
    warp.style.webkitTransform = "translateY(#{gridOffset}px)"

    offset = 0
    l = warp.childNodes.length
    scrollTop = -gridOffset
    for i in [0...l]
        if warp.childNodes[i].style.display == 'none'
            continue
        candidateId = warp.childNodes[i].id
        if scrollTop - offset < 0
            # console.log "less #{id} #{$("##{id}").firstChild.firstChild.textContent}"
            $("#grid").style.webkitMaskImage = "-webkit-linear-gradient(top, rgba(0,0,0,0), rgba(0,0,0,1) 5%, rgba(0,0,0,1) 90%, rgba(0,0,0,0.3), rgba(0,0,0,0))"
            categoryBar.focusCategory(cid.substr(Category.PREFIX.length))
            break
        else if scrollTop - offset == 0
            cid = warp.childNodes[i].id
            # console.log "equal #{id} #{$("##{id}").firstChild.firstChild.textContent}"
            if cid == "c-2"
                this.style.webkitMask = "none"
            else
                this.style.webkitMask = "-webkit-linear-gradient(top, rgba(0,0,0,1), rgba(0,0,0,1) 90%, rgba(0,0,0,0.3), rgba(0,0,0,0))"
            categoryBar.focusCategory(cid.substr(Category.PREFIX.length))
            break
        else
            cid = candidateId
            offset += warp.childNodes[i].clientHeight + CATEGORY_LIST_ITEM_MARGIN

    return
)
