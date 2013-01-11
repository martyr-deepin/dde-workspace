(function() {
  var $, $s, Loading, LoginEntry, Module, UserInfo, Widget, apply_animation, apply_flash, apply_refuse_rotate, apply_rotate, assert, build_menu, calc_text_size, create_element, create_img, date, echo, find_drag_target, format_two_bit, get_date_str, get_page_xy, get_time_str, run_post, swap_element, time, u, user, _, _current_user, _events,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; };

  Storage.prototype.setObject = function(key, value) {
    return this.setItem(key, JSON.stringify(value));
  };

  Storage.prototype.getObject = function(key) {
    return JSON.parse(this.getItem(key));
  };

  echo = function(log) {
    return console.log(log);
  };

  assert = function(value, msg) {
    if (!value) throw new Error(msg);
  };

  _ = function(s) {
    return DCore.gettext(s);
  };

  Array.prototype.remove = function(el) {
    var i;
    i = this.indexOf(el);
    if (i !== -1) return this.splice(this.indexOf(el), 1)[0];
  };

  build_menu = function(info) {
    var i, m, sm, v, _i, _len;
    m = new DeepinMenu;
    for (_i = 0, _len = info.length; _i < _len; _i++) {
      v = info[_i];
      if (v.length === 0) {
        i = new DeepinMenuItem(2, 0, 0, 0);
      } else if (typeof v[0] === "number") {
        i = new DeepinMenuItem(0, v[0], v[1], null);
        if (v.length > 2 && v[2] === false) {
          i.enabled = false;
        } else {
          i.enabled = true;
        }
      } else {
        sm = build_menu(v[1]);
        i = new DeepinMenuItem(1, 0, v[0], sm);
      }
      m.appendItem(i);
    }
    return m;
  };

  get_page_xy = function(el, x, y) {
    var p;
    return p = webkitConvertPointFromNodeToPage(el, new WebKitPoint(x, y));
  };

  find_drag_target = function(el) {
    var p;
    p = el;
    if (p.draggable) return p;
    while (p = el.parentNode) {
      if (p.draggable) return p;
    }
    return null;
  };

  swap_element = function(c1, c2) {
    var tmp;
    tmp = document.createElement('div');
    c1.parentNode.insertBefore(tmp, c1);
    c2.parentNode.insertBefore(c1, c2);
    tmp.parentNode.insertBefore(c2, tmp);
    return tmp.parentNode.removeChild(tmp);
  };

  document.body.ondrop = function(e) {
    return e.preventDefault();
  };

  run_post = function(f, self) {
    var f2;
    f2 = f.bind(self || this);
    return setTimeout(f2, 0);
  };

  create_element = function(type, clss, parent) {
    var el;
    el = document.createElement(type);
    el.setAttribute("class", clss);
    if (parent) parent.appendChild(el);
    return el;
  };

  create_img = function(clss, src, parent) {
    var el;
    el = create_element('img', clss, parent);
    el.src = src;
    el.draggable = false;
    return el;
  };

  calc_text_size = function(txt, width) {
    var h, tmp;
    tmp = create_element('div', 'hidden_calc_text', document.body);
    tmp.innerText = txt;
    tmp.style.width = "" + width + "px";
    h = tmp.clientHeight;
    document.body.removeChild(tmp);
    return h;
  };

  apply_animation = function(el, name, duration, timefunc) {
    el.style.webkitAnimationName = name;
    el.style.webkitAnimationDuration = duration;
    return el.style.webkitAnimationTimingFunction = timefunc;
  };

  apply_rotate = function(el, time) {
    apply_animation(el, "rotate", "" + time + "s", "cubic-bezier(0, 0, 0.35, -1)");
    return setTimeout(function() {
      return el.style.webkitAnimation = "";
    }, time * 1000);
  };

  apply_flash = function(el, time) {
    apply_animation(el, "flash", "" + time + "s", "cubic-bezier(0, 0, 0.35, -1)");
    return setTimeout(function() {
      return el.style.webkitAnimation = "";
    }, time * 1000);
  };

  Module = (function() {
    var moduleKeywords;

    function Module() {}

    moduleKeywords = ['extended', 'included'];

    Module.extended = function(obj) {
      var key, value, _ref;
      for (key in obj) {
        value = obj[key];
        if (__indexOf.call(moduleKeywords, key) < 0) this[key] = value;
      }
      if ((_ref = obj.extended) != null) _ref.apply(this);
      return this;
    };

    Module.included = function(obj, parms) {
      var key, value, _ref, _ref2;
      for (key in obj) {
        value = obj[key];
        if (__indexOf.call(moduleKeywords, key) < 0) this.prototype[key] = value;
      }
      if ((_ref = obj.included) != null) _ref.apply(this);
      return (_ref2 = obj.__init__) != null ? _ref2.call(this, parms) : void 0;
    };

    return Module;

  })();

  _events = ['blur', 'change', 'click', 'contextmenu', 'buildmenu', 'rightclick', 'copy', 'cut', 'dblclick', 'error', 'focus', 'keydown', 'keypress', 'keyup', 'mousedown', 'mousemove', 'mouseout', 'mouseover', 'mouseup', 'mousewheel', 'paste', 'reset', 'resize', 'scroll', 'select', 'submit', 'DOMActivate', 'DOMAttrModified', 'DOMCharacterDataModified', 'DOMFocusIn', 'DOMFocusOut', 'DOMMouseScroll', 'DOMNodeInserted', 'DOMNodeRemoved', 'DOMSubtreeModified', 'textInput', 'dragstart', 'dragend', 'dragover', 'drag', 'drop', 'dragenter', 'dragleave', 'itemselected', 'webkitTransitionEnd'];

  Widget = (function(_super) {

    __extends(Widget, _super);

    Widget.object_table = {};

    Widget.look_up = function(id) {
      return this.object_table[id];
    };

    function Widget() {
      var el, f_menu, f_rclick, k, key, v, _ref,
        _this = this;
      el = document.createElement('div');
      el.setAttribute('class', this.constructor.name);
      el.id = this.id;
      this.element = el;
      Widget.object_table[this.id] = this;
      f_menu = null;
      f_rclick = null;
      _ref = this.constructor.prototype;
      for (k in _ref) {
        v = _ref[k];
        if (!(k.search("do_") === 0)) continue;
        key = k.substr(3);
        if (__indexOf.call(_events, key) >= 0) {
          if (key === "rightclick") {
            f_rclick = v.bind(this);
          } else if (key === "buildmenu") {
            f_menu = v.bind(this);
          } else if (key === "contextmenu") {
            "nothing should do";
          } else {
            this.element.addEventListener(key, v.bind(this));
          }
        } else {
          echo("found the do_ prefix but the name " + key + " is not an dom events");
        }
      }
      this.element.addEventListener("contextmenu", function(e) {
        if (f_menu) _this.element.contextMenu = build_menu(f_menu());
        if (f_rclick) return f_rclick(e);
      });
    }

    Widget.prototype.destroy = function() {
      var _ref;
      if ((_ref = this.element.parentElement) != null) {
        _ref.removeChild(this.element);
      }
      return delete Widget.object_table[this.id];
    };

    Widget.prototype.add_css_class = function(name) {
      return this.element.classList.add(name);
    };

    Widget.prototype.remove_css_class = function(name) {
      return this.element.classList.remove(name);
    };

    return Widget;

  })(Module);

  $ = function(q, o) {
    var _ref;
    return (_ref = $s(q, o)) != null ? _ref[0] : void 0;
  };

  $s = function(q, o) {
    var div, selector;
    if (typeof q !== 'string') {
      div = q;
      selector = o;
    } else {
      div = document;
      selector = q;
    }
    switch (selector.charAt(0)) {
      case '#':
        return [div.getElementById(selector.substr(1))];
      case '.':
        return div.getElementsByClassName(selector.substr(1));
      default:
        return div.getElementsByTagName(selector);
    }
  };

  format_two_bit = function(s) {
    if (s < 10) {
      return "0" + s;
    } else {
      return s;
    }
  };

  get_time_str = function() {
    var hours, min;
    hours = format_two_bit(new Date().getHours());
    min = format_two_bit(new Date().getMinutes());
    return "" + hours + ":" + min;
  };

  get_date_str = function() {
    var date, day, day_list, mon, month_list, year;
    month_list = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    day_list = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
    day = day_list[new Date().getDay()];
    mon = month_list[new Date().getMonth()];
    date = new Date().getDate();
    year = new Date().getFullYear();
    return "" + day + ", " + mon + " " + date + ", " + year;
  };

  time = $("#time");

  date = $("#date");

  time.innerText = get_time_str();

  date.innerText = get_date_str();

  setInterval(function() {
    time.innerText = get_time_str();
    return true;
  }, 1000);

  setInterval(function() {
    time.innerText = get_time_str();
    return true;
  }, 1000);

  apply_refuse_rotate = function(el, time) {
    apply_animation(el, "refuse", "" + time + "s", "linear");
    return setTimeout(function() {
      return el.style.webkitAnimation = "";
    }, time * 1000);
  };

  LoginEntry = (function(_super) {

    __extends(LoginEntry, _super);

    function LoginEntry(id, on_active) {
      var _this = this;
      this.id = id;
      this.on_active = on_active;
      LoginEntry.__super__.constructor.apply(this, arguments);
      this.password = create_element("input", "Password", this.element);
      this.password.setAttribute("type", "password");
      this.password.index = 0;
      this.password.addEventListener("keydown", function(e) {
        if (e.which === 13) return _this.on_active(_this.password.value);
      });
      this.login = create_element("button", "LoginButton", this.element);
      this.login.innerText = "UnLock";
      this.login.addEventListener("click", function() {
        return _this.on_active(_this.password.value);
      });
      this.login.index = 1;
      this.password.focus();
    }

    return LoginEntry;

  })(Widget);

  Loading = (function(_super) {

    __extends(Loading, _super);

    function Loading(id) {
      this.id = id;
      Loading.__super__.constructor.apply(this, arguments);
      create_element("div", "ball", this.element);
      create_element("div", "ball1", this.element);
      create_element("span", "", this.element).innerText = "Welcome !";
    }

    return Loading;

  })(Widget);

  _current_user = null;

  UserInfo = (function(_super) {

    __extends(UserInfo, _super);

    function UserInfo(id, name, img_src) {
      this.id = id;
      UserInfo.__super__.constructor.apply(this, arguments);
      this.li = create_element("li", "");
      this.li.appendChild(this.element);
      this.img = create_img("UserImg", img_src, this.element);
      this.name = create_element("span", "UserName", this.element);
      this.name.innerText = name;
      this.active = false;
      this.login_displayed = false;
    }

    UserInfo.prototype.focus = function() {
      if (_current_user != null) _current_user.blur();
      _current_user = this;
      return this.add_css_class("UserInfoSelected");
    };

    UserInfo.prototype.blur = function() {
      var _ref, _ref2;
      this.element.setAttribute("class", "UserInfo");
      if ((_ref = this.login) != null) _ref.destroy();
      this.login = null;
      if ((_ref2 = this.loading) != null) _ref2.destroy();
      return this.loading = null;
    };

    UserInfo.prototype.show_login = function() {
      var _this = this;
      if (false) {
        return this.login();
      } else if (!this.login) {
        this.login = new LoginEntry("login", function(p) {
          return _this.on_verify(p);
        });
        this.element.appendChild(this.login.element);
        this.login.password.focus();
        return this.login_displayed = true;
      }
    };

    UserInfo.prototype.do_click = function(e) {
      if (_current_user === this) {
        if (!this.login) {
          return this.show_login();
        } else {
          if (e.target.parentElement === this.login.element) {
            return echo("login pwd clicked");
          } else {
            if (this.login_displayed) {
              this.focus();
              return this.login_displayed = false;
            }
          }
        }
      } else {
        return this.focus();
      }
    };

    UserInfo.prototype.on_verify = function(password) {
      this.login.destroy();
      this.loading = new Loading("loading");
      this.element.appendChild(this.loading.element);
      return DCore.Lock.try_unlock(password);
    };

    UserInfo.prototype.unlock_check = function(msg) {
      var _this = this;
      if (msg.status === "succeed") {
        return DCore.Lock.unlock_succeed();
      } else {
        this.focus();
        this.show_login();
        this.login.password.setAttribute("type", "text");
        this.login.password.style.color = "red";
        this.login.password.value = msg.status;
        this.login.password.blur();
        this.login.password.addEventListener("focus", function(e) {
          _this.login.password.setAttribute("type", "password");
          _this.login.password.style.color = "black";
          return _this.login.password.value = "";
        });
        return apply_refuse_rotate(this.element, 0.5);
      }
    };

    return UserInfo;

  })(Widget);

  user = DCore.Lock.get_username();

  u = new UserInfo(user, user, "images/img01.jpg");

  u.focus();

  $("#roundabout").appendChild(u.li);

  DCore.signal_connect("unlock", function(msg) {
    return u.unlock_check(msg);
  });

}).call(this);
