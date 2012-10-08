(function() {
  var DesktopApplet, DesktopEntry, Folder, Item, Module, NormalFile, Widget, assert, clear_occupy, cols, connect_default_signals, create_item, detect_occupy, div_grid, do_item_delete, do_item_rename, do_item_update, do_workarea_changed, draw_grid, echo, find_free_position, i, i1, i2, i_height, i_width, info, load_position, m, move_to_anywhere, move_to_position, o_table, pixel_to_position, rows, s_height, s_width, s_x, s_y, set_occupy, sort_item, update_gird_position, w, _i, _len, _ref,
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

  s_width = 1280;

  s_height = 546;

  s_x = 0;

  s_y = 100;

  i_width = 80;

  i_height = 84;

  cols = Math.floor(s_width / i_width);

  rows = Math.floor(s_height / i_height);

  o_table = new Array();

  for (i = 0; 0 <= cols ? i <= cols : i >= cols; 0 <= cols ? i++ : i--) {
    o_table[i] = new Array(rows);
  }

  update_gird_position = function(wa_x, wa_y, wa_width, wa_height) {
    s_x = wa_x;
    s_y = wa_y;
    s_width = wa_width;
    s_height = wa_height;
    div_grid.style.left = s_x;
    div_grid.style.top = s_y;
    div_grid.style.width = s_width;
    return div_grid.style.height = s_height;
  };

  load_position = function(widget) {
    return localStorage.getObject(widget.path);
  };

  clear_occupy = function(info) {
    var i, j, _ref, _results;
    _results = [];
    for (i = 0, _ref = info.width - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
      _results.push((function() {
        var _ref2, _results2;
        _results2 = [];
        for (j = 0, _ref2 = info.height - 1; 0 <= _ref2 ? j <= _ref2 : j >= _ref2; 0 <= _ref2 ? j++ : j--) {
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
    for (i = 0, _ref = info.width - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
      _results.push((function() {
        var _ref2, _results2;
        _results2 = [];
        for (j = 0, _ref2 = info.height - 1; 0 <= _ref2 ? j <= _ref2 : j >= _ref2; 0 <= _ref2 ? j++ : j--) {
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
    for (i = 0, _ref = info.width - 1; 0 <= _ref ? i <= _ref : i >= _ref; 0 <= _ref ? i++ : i--) {
      for (j = 0, _ref2 = info.height - 1; 0 <= _ref2 ? j <= _ref2 : j >= _ref2; 0 <= _ref2 ? j++ : j--) {
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
    for (i = 0; 0 <= cols ? i <= cols : i >= cols; 0 <= cols ? i++ : i--) {
      _results.push((function() {
        var _results2;
        _results2 = [];
        for (j = 0; 0 <= rows ? j <= rows : j >= rows; 0 <= rows ? j++ : j--) {
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

  div_grid = document.createElement("div");

  div_grid.setAttribute("id", "item_grid");

  document.body.appendChild(div_grid);

  update_gird_position(s_x, s_y, s_width, s_height);

  $("#item_grid").drop({
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
        path = Desktop.Core.move_to_desktop(file.path);
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

  connect_default_signals = function() {
    Desktop.Core.signal_connect("item_update", do_item_update);
    Desktop.Core.signal_connect("item_delete", do_item_delete);
    Desktop.Core.signal_connect("item_rename", do_item_rename);
    Desktop.Core.signal_connect("workarea_changed", do_workarea_changed);
    return Desktop.Core.notify_workarea_size();
  };

  do_item_delete = function(id) {
    var w;
    w = Widget.look_up(id);
    if (w != null) return w.destroy();
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
    echo("do_workarea_changed");
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

  m = new DeepinMenu();

  i1 = new DeepinMenuItem("Open");

  i2 = new DeepinMenuItem("Close");

  m.appendItem(i1);

  m.appendItem(i2);

  Item = (function(_super) {

    __extends(Item, _super);

    function Item(name, icon, exec, path) {
      var el, info;
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
      el.setAttribute("tabindex", 0);
      el.draggable = true;
      el.innerHTML = "        <img draggable=false src=" + this.icon + " />        <div contentEditable=true class=item_name>" + this.name + "</div>        ";
      this.element.addEventListener('dblclick', function() {
        return Desktop.Core.run_command(exec);
      });
      if (typeof this.init_drag === "function") this.init_drag();
      if (typeof this.init_drop === "function") this.init_drop();
      this.element.contextMenu = m;
    }

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
      Folder.__super__.constructor.apply(this, arguments);
    }

    Folder.prototype.icon_open = function() {
      return $(this.element).find("img")[0].src = Desktop.Core.get_folder_open_icon();
    };

    Folder.prototype.icon_close = function() {
      return $(this.element).find("img")[0].src = Desktop.Core.get_folder_close_icon();
    };

    Folder.prototype.init_drop = function() {
      var _this = this;
      return $(this.element).drop({
        drop: function(evt) {
          var file;
          file = evt.dataTransfer.getData("text/uri-list");
          evt.preventDefault();
          _this.icon_close();
          return _this.move_in(file);
        },
        over: function(evt) {
          var path;
          evt.preventDefault();
          path = evt.dataTransfer.getData("text/uri-list");
          if (path === ("file://" + _this.path)) {
            return evt.dataTransfer.dropEffect = "none";
          } else {
            evt.dataTransfer.dropEffect = "link";
            return _this.icon_open();
          }
        },
        enter: function(evt) {},
        leave: function(evt) {
          return _this.icon_close();
        }
      });
    };

    Folder.prototype.move_in = function(c_path) {
      var p;
      p = c_path.replace("file://", "");
      return Desktop.Core.run_command("mv '" + p + "' '" + this.path + "'");
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

  connect_default_signals();

  _ref = Desktop.Core.get_desktop_items();
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    info = _ref[_i];
    w = create_item(info);
    if (w != null) move_to_anywhere(w);
  }

}).call(this);
