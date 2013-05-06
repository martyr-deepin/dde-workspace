/**
 * 非阻塞JS文件加载, 对CSS文件也可以加载.
 * 文件加载顺序:
 *   1. 最先加载CSS文件,
 *   2. 然后加载所有同步的JS文件(并且按add方法添加的顺序),
 *   3. 最后加载所有非同步的JS文件(不一定按add方法添加的顺序).
 * 加载CSS文件方法: loader.addcss('path/to/file.css', 'screen print');
 * 加载同步JS文件方法: loader.add('path/to/file.js', true[, callback[, callback_args]]);
 * 加载非同步JS文件方法: loader.add('path/to/file.js'[, false[, callback[, callback_args]]]);
 * 如果JS文件之间有依赖关系, 应当作为同步文件加载, 且按顺序调用add方法, 否则, 应以非同步文件加载
 */
(function () {
    
    var loader = {},
    _version = '0.0.1',
    syncjs = [], // 同步的JS
    asyncjs = [], // 非同步的JS
    css = [], // CSS
    
    // 加载CSS文件
    _loadcss = function () {
        var head = document.getElementsByTagName('head')[0];
        for (var i = 0, l = css.length; i < l; i++) {
            var c = document.createElement('link');
            c.type = 'text/css';
            c.rel = 'stylesheet';
            c.href = css[i].src;
            c.media = css[i].media;
            head.appendChild(c);
        }
        css = [];
    },
    
    // JS回调函数
    // f 回调函数, 或包含回调函数的数组
    // a 回调函数的参数
    // o JS Element 对象
    _onload = function (f, a, o) {
        if (o) {
            if (typeof f === 'function') {
                f = [f];
            }
            if (o.readyState) {
                o.onreadystatechange = function () {
                    if (o.readyState == 'loaded' || o.readyState == 'complete') {
                        o.onreadystatechange = null;
                        for (var i = 0, l = f.length; i < l; i++) {
                            f[i](a);
                        }
                    }
                }
            } else {
                o.onload = function () {
                    for (var i = 0, l = f.length; i < l; i++) {
                        f[i](a);
                    }
                }
            }
        }
    },
    
    // o 用add方法增加的JS对象
    // p JS Script标签的父元素
    // f 回调函数
    _loadjs = function (o, p, f) {
        var fs = [], js = document.createElement('script');
        js.type = 'text/javascript';
        if (typeof o.callback === 'function') {
            fs.push(o.callback);
        }
        if (typeof f === 'function') {
            fs.push(f);
        }
        if (fs.length > 0) {
            _onload(fs, o.args, js);
        }
        js.src = o.src;
        p.appendChild(js);
    },
    
    // 加载同步的JS文件
    _loadsyndjs = function () {
        if (syncjs.length > 0) {
            var head = document.getElementsByTagName('head')[0],
                js = syncjs.shift();
                _loadjs(js, head, _loadsyndjs);
        } else {
            _loadasyncjs();
        }
    },
    
    // 加载非同步的JS文件
    _loadasyncjs = function () {
        var head = document.getElementsByTagName('head')[0];
        for (var i = 0, l = asyncjs.length; i < l; i++) {
            _loadjs(asyncjs[i], head);
        }
        asyncjs = [];
    };
    
    /**
     * JS或CSS文件是否已经包含了
     */
    syncjs.has = asyncjs.has = css.has = function (v) {
        for (var i = 0, l = this.length; i < l; i++) {
            if (v == this[i].src) return true;
        }
        return false;
    }
    
    /**
     * 加载JS
     * @param u JS路径
     * @param sync 是否同步
     * @param callback 加载完成后的回调函数
     * @param args 回调函数的参数
     */
    loader.add = function (u, sync, callback, args) {
        var js = sync ? syncjs : asyncjs;
        if (!js.has(u)) {
            js.push({'src': u, 'callback': callback, 'args': args});
        }
        return this;
    };
    
    /**
     * 加载CSS
     * @param u CSS路径
     * @param media CSS毁林类型
     */
    loader.addcss = function (u, media) {
        // if (!css.has(u)) {
            css.push({'src': u, 'media': media || 'screen'});
        // }
        return this;
    };
    
    /**
     * 开始加载
     */
    loader.load = function () {
        _loadcss();
        _loadsyndjs();
    };
    
    /**
     * 版本
     */
    loader.version = function () {
        return _version;
    };
    
    window.loader = loader;
})(window);