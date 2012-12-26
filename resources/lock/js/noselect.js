
        //禁止选择内容(IE)

        document.onselectstart = function() { return false; }

        //如果是移动事件则禁用

        document.onmousemove = function(e){return false;}

        //如果点击的是图片者禁用,如果使用了禁止移动事件的话，下面这个句已经不太重要，

        document.onmousedown = function(e)

        {

            if (e != null)

            {

                if (e.explicitOriginalTarget.localName == "img")

                {

                    return false;

                }

            } else

            {

                if (event.srcElement.tagName == "IMG")

                {

                    return false;

                }

            }

        }
