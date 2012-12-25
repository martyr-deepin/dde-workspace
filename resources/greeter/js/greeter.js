(function() {
  var $, $s, DEText, MenuContainer, Module, Time, Ver, Widget, apply_animation, apply_rotate, assert, build_menu, create_element, create_img, de_container, detext_container, echo, find_drag_target, format_two_bit, get_date_str, get_de_info, get_page_xy, get_power_info, get_time_str, hibernate, power_container, restart, run_post, shutdown, suspend, swap_element, time_container, ver_container, _, _events,
    __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; },
    __hasProp = Object.prototype.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

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

  get_power_info = function() {
    var power_info;
    echo("get power info");
    power_info = {};
    if (DCore.Greeter.get_can_suspend()) power_info["suspend"] = suspend;
    if (DCore.Greeter.get_can_hibernate()) power_info["hibernate"] = hibernate;
    if (DCore.Greeter.get_can_restart()) power_info["restart"] = restart;
    if (DCore.Greeter.get_can_shutdown()) power_info["shutdown"] = shutdown;
    return power_info;
  };

  suspend = function() {
    return echo("suspend");
  };

  hibernate = function() {
    return echo("hibernate");
  };

  restart = function() {
    return echo("restart");
  };

  shutdown = function() {
    return echo("shutdown");
  };

  get_de_info = function() {
    var de_info;
    echo("get desktop environment info");
    de_info = {
      "gnome": "gnome",
      "deepin": "deepin"
    };
    return de_info;
  };

  Time = (function(_super) {

    __extends(Time, _super);

    function Time(id) {
      var _this = this;
      this.id = id;
      Time.__super__.constructor.apply(this, arguments);
      document.body.appendChild(this.element);
      this.time_div = create_element("div", "Time01", this.element);
      this.date_div = create_element("div", "Time02", this.element);
      this.update();
      setInterval(function() {
        return _this.update();
      }, 1000);
    }

    Time.prototype.update = function() {
      this.time_div.innerText = get_time_str();
      this.date_div.innerText = get_date_str();
      return true;
    };

    return Time;

  })(Widget);

  time_container = new Time("time");

  Ver = (function(_super) {

    __extends(Ver, _super);

    function Ver(id) {
      this.id = id;
      Ver.__super__.constructor.apply(this, arguments);
      document.body.appendChild(this.element);
    }

    return Ver;

  })(Widget);

  ver_container = new Ver("deepin");

  DEText = (function(_super) {

    __extends(DEText, _super);

    function DEText(id) {
      this.id = id;
      DEText.__super__.constructor.apply(this, arguments);
      document.body.appendChild(this.element);
      this.element.innerText = "Choose Desktop Environment";
    }

    return DEText;

  })(Widget);

  detext_container = new DEText("detext");

  MenuContainer = (function(_super) {

    __extends(MenuContainer, _super);

    function MenuContainer(id, items) {
      this.id = id;
      this.items = items;
      this.on_menu_click = __bind(this.on_menu_click, this);
      MenuContainer.__super__.constructor.apply(this, arguments);
      document.body.appendChild(this.element);
      this.control_div = create_element("div", "MenuControl", this.element);
      this.switch_div = create_element("div", "MenuSwitch", this.control_div);
      this.menu_div = create_element("div", "Menu", this.control_div);
      this.create_menu_items();
    }

    MenuContainer.prototype.create_menu_items = function() {
      var key, menu_li, value, _ref, _results;
      this.menu_ul = create_element("ul", " ", this.menu_div);
      _ref = this.items;
      _results = [];
      for (key in _ref) {
        value = _ref[key];
        menu_li = create_element("li", " ", this.menu_ul);
        menu_li.innerText = key;
        _results.push(menu_li.addEventListener("click", this.on_menu_click));
      }
      return _results;
    };

    MenuContainer.prototype.on_menu_click = function(event) {
      var key;
      key = event.srcElement.innerText;
      return this.items[key]();
    };

    return MenuContainer;

  })(Widget);

  de_container = new MenuContainer("desktop", get_de_info());

  power_container = new MenuContainer("power", get_power_info());

}).call(this);
