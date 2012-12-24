(function() {
  var $, $s, AppItem, AppList, ClientGroup, CustomTrayIcon, Indicator, Launcher, LauncherItem, Module, PWContainer, PreviewWindow, Preview_container, ShowDesktop, TrayIconWrap, Widget, active_group, app_list, apply_animation, apply_rotate, assert, build_menu, c, calc_app_item_size, create_element, create_img, do_tray_icon_added, do_tray_icon_removed, echo, find_drag_target, format_two_bit, get_mode_board_size, get_mode_size, get_page_xy, get_time_str, icon, indicator, info, logout_icon, na, run_post, s_manager, show_desktop, show_launcher, shutdown_icon, swap_element, tray_icons, update_icons, _, _events, _i, _is_normal_mode, _len, _ref,
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

  PWContainer = (function(_super) {

    __extends(PWContainer, _super);

    function PWContainer(id) {
      this.id = id;
      PWContainer.__super__.constructor.apply(this, arguments);
      document.body.appendChild(this.element);
      this.current_group = null;
      this.update_id = -1;
      this.hide_id = null;
      this.show_id = null;
    }

    PWContainer.prototype.do_mouseover = function() {
      return clearTimeout(this.hide_id);
    };

    PWContainer.prototype._update = function() {
      var pw, _i, _len, _ref, _ref2,
        _this = this;
      _ref = this.element.children;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        pw = _ref[_i];
        if ((_ref2 = Widget.look_up(pw.id)) != null) _ref2.update_content();
      }
      return this.update_id = setInterval(function() {
        var pw, _j, _len2, _ref3, _ref4, _results;
        _ref3 = _this.element.children;
        _results = [];
        for (_j = 0, _len2 = _ref3.length; _j < _len2; _j++) {
          pw = _ref3[_j];
          _results.push((_ref4 = Widget.look_up(pw.id)) != null ? _ref4.update_content() : void 0);
        }
        return _results;
      }, 500);
    };

    PWContainer.prototype.remove_all = function(timeout) {
      var __remove_all,
        _this = this;
      __remove_all = function() {
        DCore.Dock.release_region(0, -_this.element.clientHeight, screen.width, _this.element.clientHeight);
        clearInterval(_this.update_id);
        _this.update_id = -1;
        return _this.current_group = null;
      };
      clearTimeout(this.show_id);
      if (timeout != null) {
        return this.hide_id = setTimeout(__remove_all, timeout);
      } else {
        return __remove_all();
      }
    };

    PWContainer.prototype.show_group = function(group) {
      var _show_group_,
        _this = this;
      _show_group_ = function() {
        clearTimeout(_this.hide_id);
        _this.current_group = group;
        group.clients.forEach(function(id) {
          var info, pw;
          info = group.client_infos[id];
          if (!Widget.look_up("pw" + id)) {
            pw = new PreviewWindow("pw" + id, id, info.title, 200, 100);
            return _this.element.appendChild(pw.element);
          }
        });
        if (_this.element.clientWidth === screen.width) {
          _this.element.style.left = 0;
          DCore.Dock.require_region(0, -_this.element.clientHeight, _this.element.clientWidth, _this.element.clientHeight);
        } else {
          run_post(function() {
            var offset;
            offset = group.element.offsetLeft - this.element.clientWidth / 2 + group.element.clientWidth / 2;
            return this.element.style.left = offset + "px";
          }, _this);
          run_post(function() {
            var offset;
            offset = this.element.offsetLeft;
            return DCore.Dock.require_region(offset, -this.element.clientHeight, this.element.clientWidth, this.element.clientHeight);
          }, _this);
        }
        return _this._update();
      };
      if (this.current_group === null) {
        return this.show_id = setTimeout(function() {
          return _show_group_(group);
        }, 1000);
      } else if (this.current_group === group) {
        return clearTimeout(this.hide_id);
      } else if (this.current_group !== null) {
        this.remove_all();
        echo("remove all.. and show");
        return _show_group_(group);
      }
    };

    return PWContainer;

  })(Widget);

  Preview_container = new PWContainer("pwcontainer");

  PreviewWindow = (function(_super) {

    __extends(PreviewWindow, _super);

    function PreviewWindow(id, w_id, title, width, height) {
      var _this = this;
      this.id = id;
      this.w_id = w_id;
      this.title = title;
      this.width = width;
      this.height = height;
      PreviewWindow.__super__.constructor.apply(this, arguments);
      this.element.innerHTML = "        <canvas class=PWCanvas id=c" + this.id + " width=" + this.width + "px height=" + this.height + "px></canvas>        <div class=PWTitle title='" + this.title + "'>" + this.title + "</div>        <div class=PWClose>X</div>        ";
      $(this.element, ".PWClose").addEventListener('click', function(e) {
        DCore.Dock.close_window(_this.w_id);
        e.stopPropagation();
        return _this.destroy();
      });
    }

    PreviewWindow.prototype.do_click = function(e) {
      return DCore.Dock.set_active_window(this.w_id);
    };

    PreviewWindow.prototype.update_content = function() {
      return DCore.Dock.draw_window_preview($("#c" + this.id), this.w_id, 200, 100);
    };

    return PreviewWindow;

  })(Widget);

  DCore.signal_connect("leave-notify", function() {
    return Preview_container.remove_all(1000);
  });

  calc_app_item_size = function() {
    var apps, height, i, last, offset, w, _i, _len;
    apps = $s(".AppItem");
    if (apps.length === 0) return;
    w = apps[0].offsetWidth;
    for (_i = 0, _len = apps.length; _i < _len; _i++) {
      i = apps[_i];
      Widget.look_up(i.id).change_size(w);
    }
    last = apps[apps.length - 1];
    DCore.Dock.require_region(0, 0, screen.width, 30);
    offset = get_page_xy(last, 0, 0).x + last.clientWidth;
    DCore.Dock.release_region(offset, 0, screen.width - offset, 30);
    height = w * (60 - 8) / 68 + 8;
    return DCore.Dock.change_workarea_height(height);
  };

  active_group = null;

  Indicator = (function(_super) {

    __extends(Indicator, _super);

    function Indicator(id) {
      this.id = id;
      Indicator.__super__.constructor.apply(this, arguments);
      document.body.appendChild(this.element);
      this.element.style.top = "840px";
      this.hide();
    }

    Indicator.prototype.show = function(x) {
      this.last_x = x;
      this.element.style.display = "block";
      return this.element.style.left = "" + x + "px";
    };

    Indicator.prototype.hide = function() {
      return this.element.style.display = "none";
    };

    return Indicator;

  })(Widget);

  indicator = new Indicator("indicator");

  AppList = (function(_super) {

    __extends(AppList, _super);

    function AppList(id) {
      this.id = id;
      AppList.__super__.constructor.apply(this, arguments);
      $("#container").insertBefore(this.element, $("#notifyarea"));
      setTimeout(c, 200);
    }

    AppList.prototype.append = function(c) {
      this.element.appendChild(c.element);
      return run_post(calc_app_item_size);
    };

    AppList.prototype.do_drop = function(e) {
      var file;
      indicator.hide();
      file = e.dataTransfer.getData("text/uri-list").substring(7);
      if (file.length > 9) return DCore.Dock.request_dock(decodeURI(file.trim()));
    };

    AppList.prototype.show_try_dock_app = function(e) {
      var fcg, fp, lcg, lp, path, t, x;
      path = e.dataTransfer.getData("text/uri-list").trim();
      t = path.substring(path.length - 8);
      if (t === ".desktop") {
        lcg = $(".AppItem:last-of-type", this.element);
        fcg = $(".AppItem:nth-of-type(3)", this.element);
        lp = get_page_xy(lcg, lcg.clientWidth, 0);
        fp = get_page_xy(fcg, 0, 0);
        if (e.pageX > lp.x) {
          x = lp.x;
        } else if (e.pageX < fp.x) {
          x = fp.x;
        } else {
          x = e.pageX;
        }
        return indicator.show(x);
      }
    };

    AppList.prototype.do_dragover = function(e) {
      e.dataTransfer.dropEffect = "link";
      return this.show_try_dock_app(e);
    };

    AppList.prototype.do_dragleave = function(e) {
      if (e.target === this.element) return indicator.hide();
    };

    AppList.prototype.do_mouseover = function(e) {
      if (e.target === this.element) return Preview_container.remove_all(1000);
    };

    return AppList;

  })(Widget);

  app_list = new AppList("app_list");

  _is_normal_mode = 1;

  get_mode_size = function() {
    if (_is_normal_mode) {
      return 0;
    } else {
      return 26;
    }
  };

  get_mode_board_size = function() {
    if (_is_normal_mode) {
      return 0;
    } else {
      return 26;
    }
  };

  AppItem = (function(_super) {

    __extends(AppItem, _super);

    function AppItem(id, icon) {
      this.id = id;
      this.icon = icon;
      AppItem.__super__.constructor.apply(this, arguments);
      this.add_css_class("AppItem");
      this.img = create_element('img', "AppItemImg", this.element);
      this.img.src = this.icon;
      app_list.append(this);
    }

    AppItem.prototype.destroy = function() {
      AppItem.__super__.destroy.apply(this, arguments);
      return run_post(calc_app_item_size);
    };

    AppItem.prototype.change_size = function(w) {
      var board_size, board_top, img_margin;
      board_size = (48.0 / 68) * w;
      board_top = 60 - 8 - board_size;
      this.set_board_size(board_size, board_top);
      this.img.style.height = board_size * (32.0 / 48);
      this.img.style.width = board_size * (32.0 / 48);
      img_margin = board_size * 7 / 48.0;
      return this.img.style.top = img_margin + board_top + get_mode_size();
    };

    AppItem.prototype.set_board_size = function(size, top) {
      this.board.style.top = top + get_mode_board_size();
      this.board.style.width = size;
      return this.board.style.height = size;
    };

    AppItem.prototype.do_dragstart = function(e) {
      Preview_container.remove_all();
      e.dataTransfer.setData("item-id", this.element.id);
      e.dataTransfer.effectAllowed = "move";
      e.stopPropagation();
      return this.element.style.opacity = "0.5";
    };

    AppItem.prototype.do_dragend = function(e) {
      return this.element.style.opacity = "1";
    };

    AppItem.prototype.do_dragover = function(e) {
      var did, sid;
      e.preventDefault();
      sid = e.dataTransfer.getData("item-id");
      if (!sid) return;
      did = this.element.id;
      if (sid !== did) {
        swap_element(Widget.look_up(sid).element, Widget.look_up(did).element);
      }
      return e.stopPropagation();
    };

    return AppItem;

  })(Widget);

  Launcher = (function(_super) {

    __extends(Launcher, _super);

    function Launcher(id, icon, core) {
      this.id = id;
      this.icon = icon;
      this.core = core;
      Launcher.__super__.constructor.apply(this, arguments);
      this.board_img_path = "img/1_r2_c14.png";
      this.board = create_img("AppItemBoard", this.board_img_path, this.element);
      this.board.style.zIndex = -8;
    }

    Launcher.prototype.do_click = function(e) {
      return DCore.DEntry.launch(this.core, []);
    };

    Launcher.prototype.do_itemselected = function(e) {
      switch (e.id) {
        case 1:
          return DCore.DEntry.launch(this.core, []);
        case 2:
          return DCore.Dock.request_undock(this.id);
      }
    };

    Launcher.prototype.do_buildmenu = function(e) {
      return [[1, _("Run")], [], [2, _("UnDock")]];
    };

    return Launcher;

  })(AppItem);

  ShowDesktop = (function(_super) {

    __extends(ShowDesktop, _super);

    function ShowDesktop(id) {
      this.id = id;
      ShowDesktop.__super__.constructor.apply(this, arguments);
      this.add_css_class("AppItem");
      this.show = false;
      this.img.src = "img/desktop.png";
    }

    ShowDesktop.prototype.do_click = function(e) {
      this.show = !this.show;
      return DCore.Dock.show_desktop(this.show);
    };

    ShowDesktop.prototype.do_buildmenu = function() {
      return [];
    };

    return ShowDesktop;

  })(Launcher);

  LauncherItem = (function(_super) {

    __extends(LauncherItem, _super);

    function LauncherItem(id) {
      this.id = id;
      LauncherItem.__super__.constructor.apply(this, arguments);
      this.add_css_class("AppItem");
      this.img.src = "img/launcher.png";
    }

    LauncherItem.prototype.do_click = function(e) {
      this.show = !this.show;
      return DCore.run_command("launcher");
    };

    LauncherItem.prototype.do_buildmenu = function() {
      return [];
    };

    return LauncherItem;

  })(Launcher);

  ClientGroup = (function(_super) {

    __extends(ClientGroup, _super);

    function ClientGroup(id, icon, app_id) {
      this.id = id;
      this.icon = icon;
      this.app_id = app_id;
      this.do_itemselected = __bind(this.do_itemselected, this);
      ClientGroup.__super__.constructor.apply(this, arguments);
      this.try_swap_launcher();
      this.n_clients = [];
      this.w_clients = [];
      this.client_infos = {};
      this.indicate = create_img("OpenIndicate", "", this.element);
      this.in_iconfiy = false;
      this.leader = null;
      this.board_img_path = "img/1_r2_c14.png";
      this.board = create_img("AppItemBoard", this.board_img_path, this.element);
      this.board.style.zIndex = -8;
      this.board2 = create_img("AppItemBoard", this.board_img_path, this.element);
      this.board2.style.zIndex = -9;
      this.board3 = create_img("AppItemBoard", this.board_img_path, this.element);
      this.board3.style.zIndex = -10;
      this.to_normal_status();
    }

    ClientGroup.prototype.set_board_size = function(size, marginTop) {
      var h, t, w;
      ClientGroup.__super__.set_board_size.apply(this, arguments);
      this._board_margin_top = marginTop + get_mode_board_size();
      this.handle_clients_change();
      this.board2.style.width = size;
      this.board2.style.height = size;
      this.board2.style.left = "19.117647058823528%";
      this.board3.style.width = size;
      this.board3.style.height = size;
      this.board3.style.left = "23.529411764705882%";
      w = 66.0 * size / 48;
      h = w * 52 / 66;
      t = 60 - h;
      this.indicate.style.width = w;
      this.indicate.style.height = h;
      return this.indicate.style.top = t;
    };

    ClientGroup.prototype.handle_clients_change = function() {
      switch (this.n_clients.length) {
        case 1:
          this.board.style.display = "block";
          this.board2.style.display = "none";
          this.board3.style.display = "none";
          return this.board.style.top = this._board_margin_top;
        case 2:
          this.board.style.display = "block";
          this.board2.style.display = "block";
          this.board3.style.display = "none";
          this.board.style.top = this._board_margin_top + 1;
          return this.board2.style.top = this._board_margin_top - 1;
        default:
          this.board.style.display = "block";
          this.board2.style.display = "block";
          this.board3.style.display = "block";
          this.board.style.top = this._board_margin_top + 1;
          this.board2.style.top = this._board_margin_top;
          return this.board3.style.top = this._board_margin_top - 1;
      }
    };

    ClientGroup.prototype.to_active_status = function(id) {
      this.in_iconfiy = false;
      if (active_group != null) active_group.to_normal_status();
      this.indicate.src = "img/s_app_active.png";
      this.leader = id;
      DCore.Dock.active_window(this.leader);
      return active_group = this;
    };

    ClientGroup.prototype.to_normal_status = function() {
      return this.indicate.src = "img/s_app_open.png";
    };

    ClientGroup.prototype.try_swap_launcher = function() {
      var l;
      l = Widget.look_up(this.app_id);
      if (l != null) {
        swap_element(this.element, l.element);
        apply_rotate(this.element, 0.2);
        return l.destroy();
      }
    };

    ClientGroup.prototype.withdraw_child = function(id) {
      this.w_clients.push(id);
      return this.remove_client(id, true);
    };

    ClientGroup.prototype.normal_child = function(id) {
      var info;
      info = this.client_infos[id];
      this.w_clients.remove(id);
      return this.add_client(info.id);
    };

    ClientGroup.prototype.update_client = function(id, icon, title) {
      var in_withdraw;
      in_withdraw = __indexOf.call(this.w_clients, id) >= 0;
      this.client_infos[id] = {
        "id": id,
        "icon": icon,
        "title": title
      };
      if (!in_withdraw) return this.add_client(id);
    };

    ClientGroup.prototype.add_client = function(id) {
      if (this.n_clients.indexOf(id) === -1) {
        this.n_clients.remove(id);
        this.n_clients.push(id);
        apply_rotate(this.element, 1);
        if (this.leader !== id) {
          this.leader = id;
          this.update_leader();
        }
        this.handle_clients_change();
      }
      return this.element.style.display = "block";
    };

    ClientGroup.prototype.remove_client = function(id, save_info) {
      if (save_info == null) save_info = false;
      if (!save_info) delete this.client_infos[id];
      this.n_clients.remove(id);
      if (this.n_clients.length === 0) {
        if (this.w_clients.length === 0) {
          this.destroy();
        } else {
          this.element.style.display = "none";
        }
      } else if (this.leader === id) {
        this.next_leader();
      }
      return this.handle_clients_change();
    };

    ClientGroup.prototype.next_leader = function() {
      this.n_clients.push(this.n_clients.shift());
      this.leader = this.n_clients[0];
      return this.update_leader();
    };

    ClientGroup.prototype.update_leader = function() {
      return this.img.src = this.client_infos[this.leader].icon;
    };

    ClientGroup.prototype.destroy = function() {
      var info, l;
      this.element.style.display = "block";
      info = DCore.Dock.get_launcher_info(this.app_id);
      if (info) {
        l = new Launcher(info.Id, info.Icon, info.Core);
        swap_element(l.element, this.element);
        apply_rotate(l.element, 0.5);
      }
      return ClientGroup.__super__.destroy.apply(this, arguments);
    };

    ClientGroup.prototype.do_buildmenu = function() {
      return [[1, _("OpenNew")], [2, _("Close")], [], [3, _("DockMe")], [4, _("PreView(Not yet)")]];
    };

    ClientGroup.prototype.do_itemselected = function(e) {
      Preview_container.remove_all();
      switch (e.id) {
        case 1:
          return DCore.Dock.launch_by_app_id(this.app_id);
        case 2:
          return DCore.Dock.close_window(this.leader);
        case 3:
          return DCore.Dock.request_dock_by_client_id(this.leader);
      }
    };

    ClientGroup.prototype.do_click = function(e) {
      if (this.n_clients.length === 1 && active_group === this) {
        if (this.in_iconfiy) {
          return this.to_active_status(this.leader);
        } else {
          this.in_iconfiy = true;
          DCore.Dock.iconify_window(this.leader);
          return this.to_normal_status();
        }
      } else if (this.n_clients.length > 1 && active_group === this) {
        this.next_leader();
        return this.to_active_status(this.leader);
      } else {
        return this.to_active_status(this.leader);
      }
    };

    ClientGroup.prototype.do_mouseover = function(e) {};

    return ClientGroup;

  })(AppItem);

  show_desktop = new ShowDesktop("show_desktop");

  show_launcher = new LauncherItem("show_launcher");

  app_list.element.appendChild(show_desktop.element);

  app_list.element.appendChild(show_launcher.element);

  DCore.signal_connect("active_window_changed", function(info) {
    if (active_group != null) active_group.to_normal_status();
    active_group = Widget.look_up("le_" + info.clss);
    return active_group != null ? active_group.to_active_status(info.id) : void 0;
  });

  DCore.signal_connect("launcher_added", function(info) {
    var c;
    c = Widget.look_up(info.Id);
    if (c) {
      return echo("have.." + info.Id);
    } else {
      return new Launcher(info.Id, info.Icon, info.Core);
    }
  });

  DCore.signal_connect("launcher_removed", function(info) {
    var _ref;
    return (_ref = Widget.look_up(info.Id)) != null ? _ref.destroy() : void 0;
  });

  DCore.signal_connect("task_updated", function(info) {
    var leader;
    leader = Widget.look_up("le_" + info.clss);
    if (!leader) {
      leader = new ClientGroup("le_" + info.clss, info.icon, info.app_id);
    }
    return leader.update_client(info.id, info.icon, info.title);
  });

  DCore.signal_connect("task_removed", function(info) {
    var _ref;
    return (_ref = Widget.look_up("le_" + info.clss)) != null ? _ref.remove_client(info.id) : void 0;
  });

  DCore.signal_connect("task_withdraw", function(info) {
    return Widget.look_up("le_" + info.clss).withdraw_child(info.id);
  });

  DCore.signal_connect("task_normal", function(info) {
    return Widget.look_up("le_" + info.clss).normal_child(info.id);
  });

  DCore.signal_connect("in_mini_mode", function() {
    _is_normal_mode = 0;
    return run_post(calc_app_item_size());
  });

  DCore.signal_connect("in_normal_mode", function() {
    _is_normal_mode = 1;
    return run_post(calc_app_item_size());
  });

  DCore.Dock.emit_webview_ok();

  setTimeout(calc_app_item_size, 100);

  setTimeout(calc_app_item_size, 1000);

  format_two_bit = function(s) {
    if (s < 10) {
      return "0" + s;
    } else {
      return s;
    }
  };

  get_time_str = function() {
    var hours, m, min, sec, today;
    today = new Date();
    hours = today.getHours();
    if (hours > 12) {
      m = _("PM");
      hours = hours - 12;
    } else {
      m = _("AM");
    }
    hours = format_two_bit(hours);
    min = format_two_bit(today.getMinutes());
    sec = format_two_bit(today.getSeconds());
    return "" + hours + ":" + min;
  };

  c = $("#clock");

  c.innerText = get_time_str();

  setInterval(function() {
    c.innerText = get_time_str();
    return true;
  }, 1000);

  board.width = screen.width;

  board.height = 30;

  DCore.Dock.draw_board(board);

  DCore.signal_connect("dock_color_changed", function() {
    return DCore.Dock.draw_board(board);
  });

  na = $("#notifyarea");

  tray_icons = {};

  update_icons = function() {
    var k, v, _results;
    _results = [];
    for (k in tray_icons) {
      v = tray_icons[k];
      _results.push(v.update());
    }
    return _results;
  };

  TrayIconWrap = (function(_super) {

    __extends(TrayIconWrap, _super);

    function TrayIconWrap(id, clss, name) {
      this.id = id;
      this.clss = clss;
      this.name = name;
      TrayIconWrap.__super__.constructor.apply(this, arguments);
      na.appendChild(this.element);
    }

    TrayIconWrap.prototype.update = function() {
      var p;
      p = get_page_xy(this.element);
      return DCore.Dock.set_tray_icon_position(this.id, p.x, p.y);
    };

    return TrayIconWrap;

  })(Widget);

  _ref = DCore.Dock.get_tray_icon_list();
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    info = _ref[_i];
    icon = new TrayIconWrap(info.id, info["class"], info.name);
    tray_icons[info.id] = icon;
  }

  setTimeout(update_icons, 500);

  do_tray_icon_added = function(info) {
    icon = new TrayIconWrap(info.id, info["class"], info.name);
    tray_icons[info.id] = icon;
    return setTimeout(update_icons, 30);
  };

  do_tray_icon_removed = function(info) {
    icon = Widget.look_up(info.id);
    icon.destroy();
    delete tray_icons[info.id];
    return setTimeout(update_icons, 30);
  };

  DCore.signal_connect('tray_icon_added', do_tray_icon_added);

  DCore.signal_connect('tray_icon_removed', do_tray_icon_removed);

  s_manager = DCore.DBus.session("org.gnome.SessionManager");

  CustomTrayIcon = (function(_super) {

    __extends(CustomTrayIcon, _super);

    function CustomTrayIcon(id, title, icon, cb) {
      this.id = id;
      this.title = title;
      this.icon = icon;
      this.cb = cb;
      CustomTrayIcon.__super__.constructor.apply(this, arguments);
      this.element.innerHTML = "            <img src=" + this.icon + " width=24px height=24px />        ";
      na.appendChild(this.element);
    }

    CustomTrayIcon.prototype.do_click = function(e) {
      return this.cb();
    };

    return CustomTrayIcon;

  })(Widget);

  shutdown_icon = new CustomTrayIcon("shutdown", "ShutDown", "file:///usr/share/icons//Faenza-Darker/actions/48/gnome-logout.png", function() {
    return s_manager.Shutdown_sync();
  });

  logout_icon = new CustomTrayIcon("logout", "Logout", "img/log_out_48.png", function() {
    return s_manager.Logout_sync(1);
  });

}).call(this);
