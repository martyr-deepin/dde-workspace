(function() {
  var DesktopApplet, DesktopEntry, Folder, Item, MAX_ITEM_TITLE, Module, NormalFile, Widget, assert, clear_occupy, cols, connect_default_signals, create_item, create_item_grid, detect_occupy, div_grid, do_item_delete, do_item_rename, do_item_update, do_workarea_changed, draw_grid, echo, find_free_position, gi1, gi2, gi3, gm, i1, i2, i3, i4, i_height, i_width, init_grid_drop, load_desktop_all_items, load_position, m, move_to_anywhere, move_to_position, o_table, pixel_to_position, rows, s_height, s_width, s_x, s_y, selected_item, set_occupy, shorten_text, sort_item, update_gird_position, update_selected_stats,
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

  s_width = 0;

  s_height = 0;

  s_x = 0;

  s_y = 0;

  i_width = 80 + 6 * 2;

  i_height = 84 + 4 * 2;

  cols = 0;

  rows = 0;

  div_grid = null;

  o_table = null;

  selected_item = new Array;

  gm = new DeepinMenu();

  gi1 = new DeepinMenuItem(1, "New");

  gi2 = new DeepinMenuItem(2, "Reorder Icons");

  gi3 = new DeepinMenuItem(3, "Desktop Settings");

  gm.appendItem(gi1);

  gm.appendItem(gi2);

  gm.appendItem(gi3);

  update_gird_position = function(wa_x, wa_y, wa_width, wa_height) {
    var i, n, new_cols, new_rows, new_table;
    s_x = wa_x;
    s_y = wa_y;
    s_width = wa_width;
    s_height = wa_height;
    div_grid.style.left = s_x;
    div_grid.style.top = s_y;
    div_grid.style.width = s_width;
    div_grid.style.height = s_height;
    new_cols = Math.floor(s_width / i_width);
    new_rows = Math.floor(s_height / i_height);
    new_table = new Array();
    for (i = 0; 0 <= new_cols ? i <= new_cols : i >= new_cols; 0 <= new_cols ? i++ : i--) {
      new_table[i] = new Array(new_rows);
      if (i < cols) {
        for (n = 0; 0 <= cols ? n <= cols : n >= cols; 0 <= cols ? n++ : n--) {
          new_table[i][n] = o_table[i][n];
        }
      }
    }
    cols = new_cols;
    rows = new_rows;
    return o_table = new_table;
  };

  load_position = function(widget) {
    return localStorage.getObject(widget.path);
  };

  clear_occupy = function(info) {
    var i, j, _ref, _results;
    _results = [];
    for (i = 0, _ref = info.width - 1; i <= _ref; i += 1) {
      _results.push((function() {
        var _ref2, _results2;
        _results2 = [];
        for (j = 0, _ref2 = info.height - 1; j <= _ref2; j += 1) {
          _results2.push(o_table[info.x + i][info.y + j] = null);
        }
        return _results2;
      })());
    }
    return _results;
  };

  set_occupy = function(info) {
    var i, j, _ref, _results;
    assert(info !== null, "set_occupy");
    _results = [];
    for (i = 0, _ref = info.width - 1; i <= _ref; i += 1) {
      _results.push((function() {
        var _ref2, _results2;
        _results2 = [];
        for (j = 0, _ref2 = info.height - 1; j <= _ref2; j += 1) {
          _results2.push(o_table[info.x + i][info.y + j] = true);
        }
        return _results2;
      })());
    }
    return _results;
  };

  detect_occupy = function(info) {
    var i, j, _ref, _ref2;
    assert(info !== null, "detect_occupy");
    for (i = 0, _ref = info.width - 1; i <= _ref; i += 1) {
      for (j = 0, _ref2 = info.height - 1; j <= _ref2; j += 1) {
        if (o_table[info.x + i][info.y + j]) return true;
      }
    }
    return false;
  };

  pixel_to_position = function(x, y) {
    var index_x, index_y, p_x, p_y;
    p_x = x - s_x;
    p_y = y - s_y;
    index_x = Math.floor(p_x / i_width);
    index_y = Math.floor(p_y / i_height);
    echo("" + index_x + "," + index_y);
    return [index_x, index_y];
  };

  find_free_position = function(w, h) {
    var i, info, j, _ref, _ref2;
    info = {
      x: 0,
      y: 0,
      width: w,
      height: h
    };
    for (i = 0, _ref = cols - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
      for (j = 0, _ref2 = rows - 1; 0 <= _ref2 ? j <= _ref2 : j >= _ref2; 0 <= _ref2 ? j++ : j--) {
        if (!(o_table[i][j] != null)) {
          info.x = i;
          info.y = j;
          return info;
        }
      }
    }
    return null;
  };

  move_to_anywhere = function(widget) {
    var info;
    info = localStorage.getObject(widget.path);
    if (info != null) {
      return move_to_position(widget, info);
    } else {
      info = find_free_position(1, 1);
      return move_to_position(widget, info);
    }
  };

  move_to_position = function(widget, info) {
    var old_info;
    old_info = localStorage.getObject(widget.path);
    if (!(info != null)) info = localStorage.getObject(widget.path);
    if (!detect_occupy(info)) {
      localStorage.setObject(widget.path, info);
      widget.move(info.x * i_width, info.y * i_height);
      if (old_info != null) clear_occupy(old_info);
      return set_occupy(info);
    }
  };

  draw_grid = function(ctx) {
    var grid, i, j, _results;
    grid = document.querySelector("#grid");
    ctx = grid.getContext('2d');
    ctx.fillStyle = 'rgba(0, 100, 0, 0.8)';
    _results = [];
    for (i = 0; i <= cols; i += 1) {
      _results.push((function() {
        var _results2;
        _results2 = [];
        for (j = 0; j <= rows; j += 1) {
          if (o_table[i][j] != null) {
            _results2.push(ctx.fillRect(i * i_width, j * i_height, i_width - 5, i_height - 5));
          } else {
            _results2.push(ctx.clearRect(i * i_width, j * i_height, i_width - 5, i_height - 5));
          }
        }
        return _results2;
      })());
    }
    return _results;
  };

  sort_item = function() {
    var i, item, x, y, _len, _ref, _results;
    _ref = $(".item");
    _results = [];
    for (i = 0, _len = _ref.length; i < _len; i++) {
      item = _ref[i];
      x = Math.floor(i / rows);
      y = Math.ceil(i % rows);
      _results.push(echo("sort :(" + i + ", " + x + ", " + y + ")"));
    }
    return _results;
  };

  init_grid_drop = function() {
    return $("#item_grid").drop({
      "drop": function(evt) {
        var file, p_info, path, pos, _i, _len, _ref;
        echo(evt);
        _ref = evt.originalEvent.dataTransfer.files;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          file = _ref[_i];
          pos = pixel_to_position(evt.originalEvent.x, evt.originalEvent.y);
          p_info = {
            "x": pos[0],
            "y": pos[1],
            "width": 1,
            "height": 1
          };
          path = DCore.Desktop.move_to_desktop(file.path);
          localStorage.setObject(path, p_info);
        }
        return evt.dataTransfer.dropEffect = "move";
      },
      "over": function(evt) {
        evt.dataTransfer.dropEffect = "move";
        return evt.preventDefault();
      },
      "enter": function(evt) {},
      "leave": function(evt) {}
    });
  };

  update_selected_stats = function(w, env) {
    var i, _i, _len, _ref;
    if (env.ctrlKey) {
      if (selected_item.length === 0) {
        selected_item.push(w);
        return w.item_focus();
      } else {
        for (i = 0, _ref = selected_item.length; i < _ref; i += 1) {
          if (selected_item[i] === w) {
            selected_item.splice(i, 1);
            w.item_blur();
            return null;
          }
        }
        selected_item.push(w);
        return w.item_focus();
      }
    } else if (env.shiftkey) {
      return pass;
    } else {
      if (selected_item.length > 1) {
        for (_i = 0, _len = selected_item.length; _i < _len; _i++) {
          i = selected_item[_i];
          i.item_blur();
        }
        selected_item.splice(0);
        selected_item.push(w);
        return w.item_focus();
      } else if (selected_item.length === 1) {
        if (selected_item[0] === w) {
          selected_item.splice(0);
          return w.item_blur();
        } else {
          selected_item[0].item_blur();
          selected_item.splice(0);
          selected_item.push(w);
          return w.item_focus();
        }
      } else {
        selected_item.push(w);
        return w.item_focus();
      }
    }
  };

  create_item_grid = function() {
    div_grid = document.createElement("div");
    div_grid.setAttribute("id", "item_grid");
    document.body.appendChild(div_grid);
    update_gird_position(s_x, s_y, s_width, s_height);
    init_grid_drop();
    return div_grid.contextMenu = gm;
  };

  connect_default_signals = function() {
    DCore.signal_connect("item_update", do_item_update);
    DCore.signal_connect("item_delete", do_item_delete);
    DCore.signal_connect("item_rename", do_item_rename);
    DCore.signal_connect("workarea_changed", do_workarea_changed);
    return DCore.Desktop.notify_workarea_size();
  };

  do_item_delete = function(id) {
    var w;
    w = Widget.look_up(id);
    if (w != null) {
      echo(id);
      return w.destroy();
    }
  };

  do_item_update = function(info) {
    var w;
    w = create_item(info);
    if (w != null) return move_to_anywhere(w);
  };

  do_item_rename = function(data) {
    var w;
    w = Widget.look_up(data.old_id);
    w.destroy();
    w = create_item(data.info);
    if (w != null) return move_to_anywhere(w);
  };

  do_workarea_changed = function(allo) {
    return update_gird_position(allo.x + 4, allo.y + 4, allo.width - 8, allo.height - 8);
  };

  Widget = (function(_super) {

    __extends(Widget, _super);

    Widget.object_table = {};

    Widget.look_up = function(id) {
      return this.object_table[id];
    };

    function Widget() {
      var el;
      el = document.createElement('div');
      el.setAttribute('class', this.constructor.name);
      el.id = this.id;
      this.element = el;
      Widget.object_table[this.id] = this;
    }

    Widget.prototype.destroy = function() {
      this.element.parentElement.removeChild(this.element);
      return delete Widget.object_table[this.id];
    };

    Widget.prototype.move = function(x, y) {
      var style;
      style = this.element.style;
      style.position = "absolute";
      style.left = x;
      return style.top = y;
    };

    return Widget;

  })(Module);

  MAX_ITEM_TITLE = 20;

  m = new DeepinMenu();

  i1 = new DeepinMenuItem(1, "Open");

  i2 = new DeepinMenuItem(2, "Delete");

  i3 = new DeepinMenuItem(3, "Rename");

  i4 = new DeepinMenuItem(4, "Properties");

  m.appendItem(i1);

  m.appendItem(i2);

  m.appendItem(i3);

  m.appendItem(i4);

  shorten_text = function(str, n) {
    var i, mid, r, _ref;
    r = /[^\x00-\xff]/g;
    if (str.replace(r, "mm").length <= n) return str;
    mid = Math.floor(n / 2);
    n = n - 3;
    for (i = mid, _ref = str.length - 1; mid <= _ref ? i <= _ref : i >= _ref; mid <= _ref ? i++ : i--) {
      if (str.substr(0, i).replace(r, "mm").length >= n) {
        return str.substr(0, i) + "...";
      }
    }
    return str;
  };

  Item = (function(_super) {

    __extends(Item, _super);

    function Item(name, icon, exec, path) {
      var el, info, sub_item, _i, _len, _ref,
        _this = this;
      this.name = name;
      this.icon = icon;
      this.exec = exec;
      this.path = path;
      this.id = this.path;
      Item.__super__.constructor.apply(this, arguments);
      el = this.element;
      info = {
        x: 0,
        y: 0,
        width: 1,
        height: 1
      };
      el.draggable = true;
      el.innerHTML = "        <img draggable=false src=" + this.icon + " />        <div class=item_name>" + (shorten_text(this.name, MAX_ITEM_TITLE)) + "</div>        ";
      _ref = el.childNodes;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        sub_item = _ref[_i];
        if (sub_item.className === "item_name") this.item_name = sub_item;
      }
      this.element.addEventListener('click', function(e) {
        return update_selected_stats(_this, e);
      });
      this.element.addEventListener('dblclick', function() {
        return DCore.run_command(exec);
      });
      this.element.addEventListener('itemselected', function(env) {
        return echo("menu clicked:id=" + env.id + " title=" + env.title);
      });
      if (typeof this.init_drag === "function") this.init_drag();
      if (typeof this.init_drop === "function") this.init_drop();
      this.element.contextMenu = m;
    }

    Item.prototype.item_focus = function() {
      this.element.className += " item_selected";
      return this.item_name.innerText = this.name;
    };

    Item.prototype.item_blur = function() {
      this.element.className = this.element.className.replace(" item_selected", "");
      return this.item_name.innerText = shorten_text(this.name, MAX_ITEM_TITLE);
    };

    Item.prototype.rename = function(new_name) {
      return this.item_name.innerText = new_name;
    };

    Item.prototype.destroy = function() {
      var info;
      info = load_position(this);
      clear_occupy(info);
      return Item.__super__.destroy.apply(this, arguments);
    };

    Item.prototype.init_keypress = function() {
      document.designMode = 'On';
      return this.element.addEventListener('keydown', function(evt) {
        switch (evt.which) {
          case 113:
            return echo("Rename");
        }
      });
    };

    return Item;

  })(Widget);

  DesktopEntry = (function(_super) {

    __extends(DesktopEntry, _super);

    function DesktopEntry() {
      DesktopEntry.__super__.constructor.apply(this, arguments);
    }

    DesktopEntry.prototype.init_drag = function() {
      var el,
        _this = this;
      el = this.element;
      el.addEventListener('dragstart', function(evt) {
        evt.dataTransfer.setData("text/uri-list", "file://" + _this.path);
        evt.dataTransfer.setData("text/plain", "" + _this.name);
        return evt.dataTransfer.effectAllowed = "all";
      });
      return el.addEventListener('dragend', function(evt) {
        var info, node, pos;
        if (evt.dataTransfer.dropEffect === "move") {
          evt.preventDefault();
          node = evt.target;
          pos = pixel_to_position(evt.x, evt.y);
          info = localStorage.getObject(_this.path);
          info.x = pos[0];
          info.y = pos[1];
          return move_to_position(_this, info);
        } else if (evt.dataTransfer.dropEffect === "link") {
          node = evt.target;
          return node.parentNode.removeChild(node);
        }
      });
    };

    return DesktopEntry;

  })(Item);

  Folder = (function(_super) {

    __extends(Folder, _super);

    function Folder() {
      this.init_drop = __bind(this.init_drop, this);
      this.hide_pop_block = __bind(this.hide_pop_block, this);
      this.show_pop_block = __bind(this.show_pop_block, this);
      var _this = this;
      Folder.__super__.constructor.apply(this, arguments);
      this.div_pop = null;
      this.element.addEventListener('click', function() {
        return _this.show_pop_block();
      });
    }

    Folder.prototype.show_pop_block = function() {
      var col, items, n, p, s, str, _i, _len,
        _this = this;
      this.div_background = document.createElement("div");
      this.div_background.setAttribute("id", "pop_background");
      document.body.appendChild(this.div_background);
      this.div_background.addEventListener('click', function() {
        return _this.hide_pop_block();
      });
      this.div_background.addEventListener('contextmenu', function(env) {
        env.preventDefault;
        _this.hide_pop_block();
        return false;
      });
      this.div_pop = document.createElement("div");
      this.div_pop.setAttribute("id", "pop_grid");
      document.body.appendChild(this.div_pop);
      items = DCore.Desktop.get_items_by_dir(this.element.id);
      str = "";
      for (_i = 0, _len = items.length; _i < _len; _i++) {
        s = items[_i];
        str += "<li><img src=\"" + s.Icon + "\"><div>" + (shorten_text(s.Name, MAX_ITEM_TITLE)) + "</div></li>";
      }
      this.div_pop.innerHTML = "<ul>" + str + "</ul>";
      if (items.length <= 3) {
        col = items.length;
      } else if (items.length <= 8) {
        col = 4;
      } else if (items.length <= 15) {
        col = 5;
      } else {
        col = 6;
      }
      this.div_pop.style.width = "" + (col * i_width + 20) + "px";
      n = Math.ceil(items.length / col);
      if (n > 4) n = 4;
      n = n * i_height + 20;
      if (this.element.offsetTop > n) {
        this.div_pop.style.top = "" + (this.element.offsetTop - n) + "px";
      } else {
        this.div_pop.style.top = "" + (this.element.offsetTop + this.element.offsetHeight + 20) + "px";
      }
      n = (col * i_width) / 2 + 10;
      p = this.element.offsetLeft + this.element.offsetWidth / 2;
      if (p < n) {
        return this.div_pop.style.left = "0";
      } else if (p + n > s_width) {
        return this.div_pop.style.left = "" + (s_width - 2 * n) + "px";
      } else {
        return this.div_pop.style.left = "" + (p - n) + "px";
      }
    };

    Folder.prototype.hide_pop_block = function() {
      this.div_background.parentElement.removeChild(this.div_background);
      this.div_pop.parentElement.removeChild(this.div_pop);
      delete this.div_background;
      return delete this.div_pop;
    };

    Folder.prototype.init_drop = function() {
      var _this = this;
      return $(this.element).drop({
        drop: function(evt) {
          var file;
          evt.preventDefault();
          file = decodeURI(evt.dataTransfer.getData("text/uri-list"));
          return _this.move_in(file);
        },
        over: function(evt) {
          var path;
          evt.preventDefault();
          path = decodeURI(evt.dataTransfer.getData("text/uri-list"));
          if (path === ("file://" + _this.path)) {
            return evt.dataTransfer.dropEffect = "none";
          } else {
            return evt.dataTransfer.dropEffect = "link";
          }
        },
        enter: function(evt) {},
        leave: function(evt) {}
      });
    };

    Folder.prototype.move_in = function(c_path) {
      var p;
      echo("" + c_path + "  " + this.path);
      p = c_path.replace("file://", "");
      return DCore.run_command("mv '" + p + "' '" + this.path + "'");
    };

    return Folder;

  })(DesktopEntry);

  NormalFile = (function(_super) {

    __extends(NormalFile, _super);

    function NormalFile() {
      NormalFile.__super__.constructor.apply(this, arguments);
    }

    return NormalFile;

  })(DesktopEntry);

  DesktopApplet = (function(_super) {

    __extends(DesktopApplet, _super);

    function DesktopApplet() {
      DesktopApplet.__super__.constructor.apply(this, arguments);
    }

    return DesktopApplet;

  })(Item);

  create_item = function(info) {
    var w;
    w = null;
    switch (info.Type) {
      case "Application":
        w = new DesktopEntry(info.Name, info.Icon, info.Exec, info.EntryPath);
        break;
      case "File":
        w = new NormalFile(info.Name, info.Icon, info.Exec, info.EntryPath);
        break;
      case "Dir":
        w = new Folder(info.Name, info.Icon, info.exec, info.EntryPath);
        break;
      default:
        echo("don't support type");
    }
    div_grid.appendChild(w.element);
    return w;
  };

  load_desktop_all_items = function() {
    var info, w, _i, _len, _ref, _results;
    _ref = DCore.Desktop.get_desktop_items();
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      info = _ref[_i];
      w = create_item(info);
      if (w != null) {
        _results.push(move_to_anywhere(w));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  create_item_grid();

  connect_default_signals();

  load_desktop_all_items();

}).call(this);
