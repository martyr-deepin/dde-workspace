(function() {
  var DesktopApplet, DesktopEntry, Folder, Item, Module, NormalFile, Recordable, Widget, assert, clear_occupy, cols, create_item, detect_occupy, do_item_delete, do_item_rename, do_item_update, draw_grid, echo, find_free_position, i, i_height, i_width, load_desktop_entries, load_position, move_to_anywhere, move_to_position, o_table, pixel_to_position, rows, s_height, s_width, set_occupy, sort_item,
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

  Recordable = {
    db_tabls: [],
    __init__: function(parms) {
      this.prototype.get_fields = parms;
      return this.prototype.create_table();
    },
    table: function() {
      return "__d_" + this.constructor.name + "__";
    },
    fields: function() {
      return this.get_fields.join();
    },
    fields_n: function() {
      var i, _ref, _results;
      _results = [];
      for (i = 1, _ref = this.get_fields.length; 1 <= _ref ? i <= _ref : i >= _ref; 1 <= _ref ? i++ : i--) {
        _results.push('?');
      }
      return _results;
    },
    save: function() {
      var fn, i, values,
        _this = this;
      values = (function() {
        var _i, _len, _ref, _results;
        _ref = this.get_fields;
        _results = [];
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          i = _ref[_i];
          _results.push(this["get_" + i]());
        }
        return _results;
      }).call(this);
      fn = this.fields_n();
      return db_conn.transaction(function(tx) {
        return tx.executeSql("replace into " + (_this.table()) + " (" + (_this.fields()) + ") values (" + fn + ");", values, function(result) {}, function(tx, error) {
          return console.log(error);
        });
      });
    },
    create_table: function() {
      var fs;
      fs = this.fields().split(',').slice(1).join(' Int, ') + " Int";
      return Recordable.db_tabls.push("CREATE TABLE " + (this.table()) + " (id REAL UNIQUE, " + fs + ");");
    },
    load: function() {
      var _this = this;
      return db_conn.transaction(function(tx) {
        return tx.executeSql("select " + (_this.fields()) + " from " + (_this.table()) + " where id = ?", [_this.id], function(tx, r) {
          var field, p, _i, _len, _ref, _results;
          p = r.rows.item(0);
          _ref = _this.get_fields;
          _results = [];
          for (_i = 0, _len = _ref.length; _i < _len; _i++) {
            field = _ref[_i];
            _results.push(_this["set_" + field](p[field]));
          }
          return _results;
        }, function(tx, error) {});
      });
    }
  };

  s_width = 1280;

  s_height = 746;

  i_width = 80;

  i_height = 80;

  cols = Math.floor(s_width / i_width);

  rows = Math.floor(s_height / i_height);

  o_table = new Array();

  for (i = 0; 0 <= cols ? i <= cols : i >= cols; 0 <= cols ? i++ : i--) {
    o_table[i] = new Array(rows);
  }

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
    var p_x, p_y;
    p_x = Math.floor(x / i_width);
    p_y = Math.floor(y / i_height);
    return [p_x, p_y];
  };

  find_free_position = function(w, h) {
    var i, info, j;
    info = {
      x: 0,
      y: 0,
      width: w,
      height: h
    };
    for (i = 0; 0 <= cols ? i <= cols : i >= cols; 0 <= cols ? i++ : i--) {
      for (j = 0; 0 <= rows ? j <= rows : j >= rows; 0 <= rows ? j++ : j--) {
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

  $("body").drop({
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

  create_item = function(info, pos) {
    var w;
    w = null;
    switch (info.type) {
      case "Entry":
        w = new DesktopEntry(info.name, info.icon, info.exec, info.path);
        break;
      case "File":
        w = new NormalFile(info.name, info.icon, info.exec, info.path);
        break;
      case "Dir":
        w = new Folder(info.name, info.icon, info.exec, info.path);
        break;
      default:
        echo("don't support type");
    }
    if (pos != null) return move_to_position(w, pos);
  };

  Desktop.Core.install_monitor();

  load_desktop_entries = function() {
    var grid, info, _i, _len, _ref;
    grid = document.querySelector("#grid");
    grid.width = document.body.scrollWidth;
    grid.height = document.body.scrollHeight;
    _ref = Desktop.Core.get_desktop_items();
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      info = _ref[_i];
      create_item(info);
    }
    Desktop.Core.item_connect("update", do_item_update);
    Desktop.Core.item_connect("delete", do_item_delete);
    return Desktop.Core.item_connect("rename", do_item_rename);
  };

  do_item_delete = function(id) {
    var w;
    w = Widget.look_up(id);
    return w.destroy();
  };

  do_item_update = function(info) {
    return create_item(info);
  };

  do_item_rename = function(id, info) {
    var pos, w;
    w = Widget.look_up(id);
    pos = load_position(w);
    w.destroy();
    return create_item(info, pos);
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
      document.body.appendChild(el);
      this.element = el;
      Widget.object_table[this.id] = this;
    }

    Widget.prototype.destroy = function() {
      document.body.removeChild(this.element);
      return delete Widget.object_table[this.id];
    };

    Widget.prototype.move = function(x, y) {
      var style;
      style = this.element.style;
      style.position = "fixed";
      style.left = x;
      return style.top = y;
    };

    return Widget;

  })(Module);

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
      move_to_anywhere(this);
      el.setAttribute("tabindex", 0);
      el.draggable = true;
      el.innerHTML = "        <img draggable=false src=" + this.icon + ">            <div contenteditable=true class=item_name>" + this.name + "</div>        </img>        ";
      this.element.addEventListener('dblclick', function() {
        return Desktop.Core.run_command(exec);
      });
      if (typeof this.init_drag === "function") this.init_drag();
      if (typeof this.init_drop === "function") this.init_drop();
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
        evt.dataTransfer.effectAllowed = "all";
        return evt.dataTransfer.dropEffect = "move";
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
      return $(this.element).find("img")[0].src = "/usr/share/icons/oxygen/48x48/status/folder-open.png";
    };

    Folder.prototype.icon_close = function() {
      return $(this.element).find("img")[0].src = "/usr/share//icons/oxygen/48x48/mimetypes/inode-directory.png";
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

  $.contextMenu({
    selector: "body",
    callback: function(key, opt) {
      switch (key) {
        case "cbg":
          return Desktop.Core.run_command("gnome-control-center background");
        case "reload":
          return location.reload();
        case "sort1":
          return sort_item_by_time();
        case "sort2":
          return sort_item_by_type();
        case "sort3":
          return sort_item_by_name();
        default:
          return echo("Nothing");
      }
    },
    items: {
      "cfile": {
        name: "Create File"
      },
      "cdir": {
        name: "Create Directory"
      },
      "sepl1": "----------",
      "reload": {
        name: "*Reload"
      },
      "sepl2": "----------",
      "sort1": {
        name: "Sort By Time"
      },
      "sort2": {
        name: "Sort By Type"
      },
      "sort3": {
        name: "Sort By Name"
      },
      "sepl3": "----------",
      "cbg": {
        name: "*ChangeBackground"
      }
    }
  });

  $.contextMenu({
    selector: ".DesktopEntry, .NormalFile, .Folder",
    callback: function(key, opt) {
      var path;
      switch (key) {
        case "reload":
          return location.reload();
        case "del":
          path = opt.$trigger[0].id;
          return Desktop.Core.run_command("rm -rf -- '" + path + "'");
        case "preview":
          return echo("preview");
      }
    },
    items: {
      "preve": {
        name: "Preview"
      },
      "sort": {
        name: "Open"
      },
      "rename": {
        name: "Rename"
      },
      "del": {
        name: "*Delete"
      },
      "sepl": "--------------",
      "property": {
        name: "Property"
      }
    }
  });

  $(function() {
    return load_desktop_entries();
  });

}).call(this);
