(function() {
  var $, $s, ComboBox, Loading, LoginEntry, Menu, Module, UserInfo, Widget, apply_animation, apply_flash, apply_refuse_rotate, apply_rotate, assert, build_menu, calc_text_size, create_element, create_img, date, de_menu, de_menu_cb, default_session, echo, find_drag_target, format_two_bit, get_date_str, get_page_xy, get_power_info, get_time_str, hibernate_cb, icon, icon_path, id, key, power_dict, power_menu, power_menu_cb, restart_cb, run_post, session, sessions, shutdown_cb, suspend_cb, swap_element, time, u, user, users, value, _, _current_user, _events, _global_menu_container, _i, _j, _len, _len2,
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

  _global_menu_container = create_element("div", "", document.body);

  _global_menu_container.id = "global_menu_container";

  _global_menu_container.addEventListener("click", function(e) {
    _global_menu_container.style.display = "none";
    return _global_menu_container.removeChild(_global_menu_container.children[0]);
  });

  Menu = (function(_super) {

    __extends(Menu, _super);

    function Menu(id) {
      this.id = id;
      Menu.__super__.constructor.apply(this, arguments);
      this.current = this.id;
      this.items = {};
    }

    Menu.prototype.insert = function(id, title, img) {
      var item, _id, _img, _title,
        _this = this;
      this.id = id;
      this.title = title;
      this.img = img;
      _id = this.id;
      _title = this.title;
      item = create_element("div", "menuitem", this.element);
      item.addEventListener("click", function(e) {
        return _this.cb(_id, _title);
      });
      create_img("menuimg", this.img, item);
      title = create_element("div", "menutitle", item);
      title.innerText = this.title;
      _img = this.img;
      this.items[_id] = [_title, _img];
      return this.current = this.id;
    };

    Menu.prototype.insert_noimg = function(id, title) {
      var item, _id, _title,
        _this = this;
      this.id = id;
      this.title = title;
      _id = this.id;
      _title = this.title;
      item = create_element("div", "menuitem", this.element);
      item.addEventListener("click", function(e) {
        return _this.cb(_id, _title);
      });
      title = create_element("div", "menutitle", item);
      title.innerText = this.title;
      this.items[_id] = [_title];
      return this.current = this.id;
    };

    Menu.prototype.set_callback = function(cb) {
      this.cb = cb;
    };

    Menu.prototype.show = function(x, y) {
      this.try_append();
      this.element.style.left = x;
      return this.element.style.top = y;
    };

    Menu.prototype.try_append = function() {
      if (!this.element.parent) {
        _global_menu_container.appendChild(this.element);
        return _global_menu_container.style.display = "block";
      }
    };

    Menu.prototype.get_allocation = function() {
      var height, width;
      this.try_append();
      width = this.element.clientWidth;
      height = this.element.clientHeight;
      return {
        "width": width,
        "height": height
      };
    };

    return Menu;

  })(Widget);

  ComboBox = (function(_super) {

    __extends(ComboBox, _super);

    function ComboBox(id, on_click_cb) {
      this.id = id;
      this.on_click_cb = on_click_cb;
      ComboBox.__super__.constructor.apply(this, arguments);
      this.show_item = create_element("div", "ShowItem", this.element);
      this.current_img = create_img("", "", this.show_item);
      this["switch"] = create_element("div", "Switcher", this.element);
      this.menu = new Menu(this.id + "_menu");
      this.menu.set_callback(this.on_click_cb);
    }

    ComboBox.prototype.insert = function(id, title, img) {
      this.current_img.src = img;
      return this.menu.insert(id, title, img);
    };

    ComboBox.prototype.insert_noimg = function(id, title) {
      return this.menu.insert_noimg(id, title);
    };

    ComboBox.prototype.do_click = function(e) {
      var alloc, p, x, y;
      if (e.target === this["switch"]) {
        p = get_page_xy(e.target, 0, 0);
        alloc = this.menu.get_allocation();
        x = p.x - alloc.width + this["switch"].offsetWidth;
        y = p.y - alloc.height;
        return this.menu.show(x, y);
      }
    };

    ComboBox.prototype.get_current = function() {
      return this.menu.current;
    };

    ComboBox.prototype.set_current = function(id) {
      var _img;
      _img = this.menu.items[id][1];
      this.current_img.src = _img;
      return this.menu.current = id;
    };

    return ComboBox;

  })(Widget);

  DCore.signal_connect("status", function(msg) {
    return echo(msg.status);
  });

  de_menu_cb = function(id, title) {
    de_menu.set_current(id);
    return DCore.Greeter.set_selected_session(id);
  };

  de_menu = new ComboBox("desktop", de_menu_cb);

  power_dict = {};

  power_menu_cb = function(id, title) {
    return power_dict[title]();
  };

  power_menu = new ComboBox("power", power_menu_cb);

  sessions = DCore.Greeter.get_sessions();

  for (_i = 0, _len = sessions.length; _i < _len; _i++) {
    session = sessions[_i];
    id = session;
    icon = DCore.Greeter.get_session_icon(session);
    icon_path = "images/" + icon;
    de_menu.insert(id, session, icon_path);
  }

  default_session = DCore.Greeter.get_default_session();

  $("#bottom_buttons").appendChild(de_menu.element);

  de_menu.set_current(default_session);

  get_power_info = function() {
    var power_info;
    power_info = {};
    if (DCore.Greeter.get_can_suspend()) power_info["suspend"] = suspend_cb;
    if (DCore.Greeter.get_can_hibernate()) power_info["hibernate"] = hibernate_cb;
    if (DCore.Greeter.get_can_restart()) power_info["restart"] = restart_cb;
    if (DCore.Greeter.get_can_shutdown()) power_info["shutdown"] = shutdown_cb;
    return power_info;
  };

  suspend_cb = function() {
    alert("suspend");
    return DCore.Greeter.run_suspend();
  };

  hibernate_cb = function() {
    alert("hibernate");
    return DCore.Greeter.run_hibernate();
  };

  restart_cb = function() {
    alert("restart");
    return DCore.Greeter.run_restart();
  };

  shutdown_cb = function() {
    alert("shutdown");
    return DCore.Greeter.run_shutdown();
  };

  power_dict = get_power_info();

  for (key in power_dict) {
    value = power_dict[key];
    power_menu.insert_noimg(key, key);
  }

  power_menu.current_img.src = "images/control-power.png";

  $("#bottom_buttons").appendChild(power_menu.element);

  DCore.signal_connect("power", function(msg) {
    var status_div;
    status_div = create_element("div", " ", $("#Debug"));
    return status_div.innerText = "status:" + msg.status;
  });

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
      if (DCore.Greeter.is_hide_users()) {
        this.account = create_element("input", "Account", this.element);
        this.account.setAttribute("autofocus", "true");
        this.account.addEventListener("keydown", function(e) {
          if (e.which === 13) return _this.password.focus();
        });
        this.account.index = 0;
      }
      this.password = create_element("input", "Password", this.element);
      this.password.setAttribute("type", "password");
      this.password.focus();
      this.password.index = 1;
      this.password.addEventListener("keydown", function(e) {
        if (e.which === 13) {
          if (DCore.Greeter.is_hide_users()) {
            return _this.on_active(_this.account.value, _this.password.value);
          } else {
            return _this.on_active(_this.id, _this.password.value);
          }
        }
      });
      this.login = create_element("button", "LoginButton", this.element);
      this.login.innerText = "User Login";
      this.login.addEventListener("click", function() {
        if (DCore.Greeter.is_hide_users()) {
          return _this.on_active(_this.account.value, _this.password.value);
        } else {
          return _this.on_active(_this.id, _this.password.value);
        }
      });
      this.login.index = 2;
      if (DCore.Greeter.is_hide_users()) {
        this.account.focus();
      } else {
        this.password.focus();
      }
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
      this.add_css_class("UserInfoSelected");
      if (DCore.Greeter.in_authentication()) DCore.Greeter.cancel_authentication();
      if (DCore.Greeter.is_hide_users()) {
        return DCore.Greeter.start_authentication("*other");
      } else {
        DCore.Greeter.set_selected_user(this.id);
        return DCore.Greeter.start_authentication(this.id);
      }
    };

    UserInfo.prototype.blur = function() {
      var _ref, _ref2;
      this.element.setAttribute("class", "UserInfo");
      if ((_ref = this.login) != null) _ref.destroy();
      this.login = null;
      if ((_ref2 = this.loading) != null) _ref2.destroy();
      this.loading = null;
      if (DCore.Greeter.in_authentication()) {
        return DCore.Greeter.cancel_authentication();
      }
    };

    UserInfo.prototype.show_login = function() {
      var _this = this;
      if (false) {
        return this.login();
      } else if (!this.login) {
        this.login = new LoginEntry("login", function(u, p) {
          return _this.on_verify(u, p);
        });
        this.element.appendChild(this.login.element);
        this.login.password.focus();
        return this.login_displayed = true;
      }
    };

    UserInfo.prototype.do_click = function(e) {
      if (_current_user === this) {
        if (!this.login) {
          this.show_login();
        } else {
          if (e.target.parentElement === this.login.element) {
            echo("login pwd clicked");
          } else {
            if (this.login_displayed) {
              this.focus();
              this.login_displayed = false;
            }
          }
        }
        if (this.name.innerText === "guest") {
          return this.login.password.style.display = "none";
        }
      } else {
        return this.focus();
      }
    };

    UserInfo.prototype.on_verify = function(username, password) {
      var _session;
      this.login.destroy();
      this.loading = new Loading("loading");
      this.element.appendChild(this.loading.element);
      _session = de_menu.menu.items[de_menu.get_current()][0];
      if (DCore.Greeter.is_hide_users()) {
        DCore.Greeter.set_selected_user(username);
        DCore.Greeter.login_clicked(username);
      }
      return DCore.Greeter.login_clicked(password);
    };

    return UserInfo;

  })(Widget);

  if (DCore.Greeter.is_hide_users()) {
    u = new UserInfo("Hide user", "Hide user", "images/img01.jpg");
    roundabout.appendChild(u.li);
    u.focus();
  } else {
    users = DCore.Greeter.get_users();
    for (_j = 0, _len2 = users.length; _j < _len2; _j++) {
      user = users[_j];
      u = new UserInfo(user, user, "images/img01.jpg");
      roundabout.appendChild(u.li);
      if (user === DCore.Greeter.get_default_user()) u.focus();
    }
    if (DCore.Greeter.is_support_guest()) {
      u = new UserInfo("guest", "guest", "images/guest.jpg");
      roundabout.appendChild(u.li);
      if (DCore.Greeter.is_guest_default()) u.focus();
    }
  }

  DCore.signal_connect("message", function(msg) {
    return echo(msg.error);
  });

  DCore.signal_connect("auth", function(msg) {
    var _this = this;
    user = _current_user;
    user.focus();
    user.show_login();
    user.login.password.setAttribute("type", "text");
    user.login.password.style.color = "red";
    user.login.password.value = msg.error;
    user.login.password.blur();
    user.login.password.addEventListener("focus", function(e) {
      user.login.password.setAttribute("type", "password");
      user.login.password.style.color = "black";
      return user.login.password.value = "";
    });
    return apply_refuse_rotate(user.element, 0.5);
  });

  if (roundabout.children.length === 2) roundabout.style.width = "0";

  run_post(function() {
    var l;
    l = (screen.width - roundabout.clientWidth) / 2;
    return roundabout.style.left = "" + l + "px";
  });

}).call(this);
