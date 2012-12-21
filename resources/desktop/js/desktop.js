(function() {
  var $, $s, Application, DLCLICK_INTERVAL, DesktopApplet, DesktopEntry, FILE_TYPE_APP, FILE_TYPE_DIR, FILE_TYPE_FILE, Folder, Item, ItemGrid, MAX_ITEM_TITLE, Module, Mouse_Select_Area_box, NormalFile, Widget, all_item, apply_animation, apply_rotate, assert, build_menu, build_selected_items_menu, calc_pos_to_pos_distance, calc_row_and_cols, cancel_all_selected_stats, cancel_item_selected, cleanup_filename, clear_desktop_items, clear_occupy, clear_occupy_table, cols, compare_pos_rect, compare_pos_top_left, connect_default_signals, context, coord_to_pos, create_element, create_img, create_item, create_item_grid, delete_selected_items, detect_occupy, discard_position, div_grid, do_item_delete, do_item_rename, do_item_update, do_workarea_changed, drag_canvas, drag_image, drag_start, drag_update_selected_pos, echo, find_drag_target, find_free_position, get_page_xy, gird_left_mousedown, gm, grid_do_itemselected, grid_item_height, grid_item_width, grid_right_click, i_height, i_width, init_grid_drop, init_occupy_table, item_dragstart_handler, last_widget, load_desktop_all_items, load_position, menu_sort_desktop_item_by_mtime, menu_sort_desktop_item_by_name, move_to_anywhere, move_to_position, move_to_somewhere, o_table, open_selected_items, paste_from_clipboard, pixel_to_coord, rows, run_post, s_height, s_nautilus, s_offset_x, s_offset_y, s_width, save_position, sel, selected_copy_to_clipboard, selected_cut_to_clipboard, selected_item, set_item_selected, set_occupy, shorten_text, show_selected_items_Properties, sort_list_by_mtime_from_id, sort_list_by_name_from_id, swap_element, update_gird_position, update_position, update_selected_item_drag_image, update_selected_stats, _, _events,
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

  s_width = 0;

  s_height = 0;

  s_offset_x = 0;

  s_offset_y = 0;

  i_width = 80 + 6 * 2;

  i_height = 84 + 4 * 2;

  context = null;

  grid_item_width = 0;

  grid_item_height = 0;

  cols = 0;

  rows = 0;

  div_grid = null;

  o_table = null;

  all_item = new Array;

  selected_item = new Array;

  last_widget = "";

  drag_canvas = null;

  drag_image = null;

  drag_start = {
    x: 0,
    y: 0
  };

  sel = null;

  s_nautilus = DCore.DBus.session("org.freedesktop.FileManager1");

  gm = build_menu([[_("arrange icons"), [[11, _("by name")], [12, _("by last modified time")]]], [_("New"), [[21, _("folder")], [22, _("text file")]]], [3, _("open terminal here")], [4, _("paste")], [], [5, _("Personal")], [6, _("Display Settings")]]);

  calc_row_and_cols = function(wa_width, wa_height) {
    var gi_height, gi_width, n_cols, n_rows, xx, yy;
    n_cols = Math.floor(wa_width / i_width);
    n_rows = Math.floor(wa_height / i_height);
    xx = wa_width % i_width;
    yy = wa_height % i_height;
    gi_width = i_width + Math.floor(xx / n_cols);
    gi_height = i_height + Math.floor(yy / n_rows);
    return [n_cols, n_rows, gi_width, gi_height];
  };

  update_gird_position = function(wa_x, wa_y, wa_width, wa_height) {
    var i, w, _i, _len, _ref, _results;
    s_offset_x = wa_x;
    s_offset_y = wa_y;
    s_width = wa_width;
    s_height = wa_height;
    div_grid.style.left = s_offset_x;
    div_grid.style.top = s_offset_y;
    div_grid.style.width = s_width;
    div_grid.style.height = s_height;
    _ref = calc_row_and_cols(s_width, s_height), cols = _ref[0], rows = _ref[1], grid_item_width = _ref[2], grid_item_height = _ref[3];
    init_occupy_table();
    _results = [];
    for (_i = 0, _len = all_item.length; _i < _len; _i++) {
      i = all_item[_i];
      w = Widget.look_up(i);
      if (w != null) {
        _results.push(move_to_anywhere(w));
      } else {
        _results.push(void 0);
      }
    }
    return _results;
  };

  load_position = function(item) {
    var pos;
    pos = localStorage.getObject("id:" + item);
    if (pos === null) return null;
    if (cols > 0 && pos.x + pos.width - 1 >= cols) pos.x = cols - pos.width;
    if (cols > 0 && pos.y + pos.height - 1 >= rows) pos.y = rows - pos.height;
    return pos;
  };

  save_position = function(item, pos) {
    localStorage.setObject("id:" + item, pos);
  };

  discard_position = function(item) {
    localStorage.removeItem("id:" + item);
  };

  update_position = function(old_id, new_id) {
    var o_p;
    o_p = load_position(old_id);
    discard_position(old_id);
    save_position(new_id, o_p);
  };

  compare_pos_top_left = function(base, pos) {
    if (pos.y < base.y) {
      return -1;
    } else if (pos.y >= base.y && pos.y <= base.y + base.height - 1) {
      if (pos.x < base.x) {
        return -1;
      } else if (pos.x >= base.x && pos.x <= base.x + base.width - 1) {
        return 0;
      } else {
        return 1;
      }
    } else {
      return 1;
    }
  };

  compare_pos_rect = function(base1, base2, pos) {
    var bottom_left, bottom_right, top_left, top_right, _ref, _ref2;
    top_left = Math.min(base1.x, base2.x);
    top_right = Math.max(base1.x, base2.x);
    bottom_left = Math.min(base1.y, base2.y);
    bottom_right = Math.max(base1.y, base2.y);
    if ((top_left <= (_ref = pos.x) && _ref <= top_right) && (bottom_left <= (_ref2 = pos.y) && _ref2 <= bottom_right)) {
      return true;
    } else {
      return false;
    }
  };

  calc_pos_to_pos_distance = function(base, pos) {
    return Math.sqrt(Math.pow(Math.abs(base.x - pos.x), 2) + Math.pow(Math.abs(base.y - pos.y), 2));
  };

  init_occupy_table = function() {
    var i, _results;
    o_table = new Array();
    _results = [];
    for (i = 0; 0 <= cols ? i <= cols : i >= cols; 0 <= cols ? i++ : i--) {
      _results.push(o_table[i] = new Array(rows));
    }
    return _results;
  };

  clear_occupy_table = function() {
    var i, j, _results;
    _results = [];
    for (i = 0; 0 <= cols ? i < cols : i > cols; 0 <= cols ? i++ : i--) {
      _results.push((function() {
        var _results2;
        _results2 = [];
        for (j = 0; 0 <= rows ? j < rows : j > rows; 0 <= rows ? j++ : j--) {
          _results2.push(o_table[i][j] = null);
        }
        return _results2;
      })());
    }
    return _results;
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

  pixel_to_coord = function(x, y) {
    var index_x, index_y;
    index_x = Math.min(Math.floor(x / grid_item_width), cols - 1);
    index_y = Math.min(Math.floor(y / grid_item_height), rows - 1);
    return [index_x, index_y];
  };

  coord_to_pos = function(coord, size) {
    return {
      x: coord[0],
      y: coord[1],
      width: size[0],
      height: size[1]
    };
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
    info = load_position(widget.id);
    if ((info != null) && !detect_occupy(info)) {
      move_to_position(widget, info);
    } else {
      info = find_free_position(1, 1);
      move_to_position(widget, info);
    }
  };

  move_to_somewhere = function(widget, pos) {
    var old_pos;
    if (!detect_occupy(pos)) {
      move_to_position(widget, pos);
    } else {
      old_pos = load_position(widget.id);
      if (!(old_pos != null)) {
        pos = find_free_position(1, 1);
        move_to_position(widget, pos);
      }
    }
  };

  move_to_position = function(widget, info) {
    var old_info;
    old_info = load_position(widget.id);
    if (!(info != null)) return;
    save_position(widget.id, info);
    widget.move(info.x * grid_item_width, info.y * grid_item_height);
    if (old_info != null) clear_occupy(old_info);
    set_occupy(info);
  };

  sort_list_by_name_from_id = function(id1, id2) {
    var w1, w2;
    w1 = Widget.look_up(id1);
    w2 = Widget.look_up(id2);
    if (!(w1 != null) || !(w2 != null)) {
      echo("we get error here[sort_list_by_name_from_id]");
      return w1.localeCompare(w2);
    } else {
      return w1.get_name().localeCompare(w2.get_name());
    }
  };

  menu_sort_desktop_item_by_name = function() {
    var i, item_ordered_list, w, _i, _len;
    item_ordered_list = all_item.concat();
    item_ordered_list.sort(sort_list_by_name_from_id);
    clear_occupy_table();
    for (_i = 0, _len = item_ordered_list.length; _i < _len; _i++) {
      i = item_ordered_list[_i];
      w = Widget.look_up(i);
      if (w != null) {
        discard_position(w.id);
        move_to_anywhere(w);
      }
    }
  };

  sort_list_by_mtime_from_id = function(id1, id2) {
    var w1, w2;
    w1 = Widget.look_up(id1);
    w2 = Widget.look_up(id2);
    if (!(w1 != null) || !(w2 != null)) {
      echo("we get error here[sort_list_by_name_from_id]");
      return w1.localeCompare(w2);
    } else {
      return w1.get_mtime() - w2.get_mtime();
    }
  };

  menu_sort_desktop_item_by_mtime = function() {
    var i, item_ordered_list, w, _i, _len;
    item_ordered_list = all_item.concat();
    item_ordered_list.sort(sort_list_by_mtime_from_id);
    clear_occupy_table();
    for (_i = 0, _len = item_ordered_list.length; _i < _len; _i++) {
      i = item_ordered_list[_i];
      w = Widget.look_up(i);
      if (w != null) {
        discard_position(w.id);
        move_to_anywhere(w);
      }
    }
  };

  init_grid_drop = function() {
    var _this = this;
    div_grid.addEventListener("drop", function(evt) {
      var file, path, pos, _i, _len, _ref;
      evt.preventDefault();
      evt.stopPropagation();
      _ref = evt.dataTransfer.files;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        file = _ref[_i];
        pos = coord_to_pos(pixel_to_coord(evt.clientX, evt.clientY), [1, 1]);
        path = DCore.Desktop.move_to_desktop(file.path);
        if (path.length > 1) save_position(path, pos);
      }
    });
    div_grid.addEventListener("dragover", function(evt) {
      evt.preventDefault();
      evt.stopPropagation();
      evt.dataTransfer.dropEffect = "move";
    });
    div_grid.addEventListener("dragenter", function(evt) {
      evt.stopPropagation();
      evt.dataTransfer.dropEffect = "move";
    });
    return div_grid.addEventListener("dragleave", function(evt) {
      evt.stopPropagation();
    });
  };

  drag_update_selected_pos = function(w, evt) {
    var coord_x_shift, coord_y_shift, dis, distance_list, i, j, new_pos, old_pos, ordered_list, pos, _i, _j, _len, _len2, _ref;
    old_pos = load_position(w.id);
    new_pos = coord_to_pos(pixel_to_coord(evt.x, evt.y), [1, 1]);
    coord_x_shift = new_pos.x - old_pos.x;
    coord_y_shift = new_pos.y - old_pos.y;
    if (coord_x_shift === 0 && coord_y_shift === 0) return;
    ordered_list = new Array();
    distance_list = new Array();
    for (_i = 0, _len = selected_item.length; _i < _len; _i++) {
      i = selected_item[_i];
      pos = load_position(i);
      dis = calc_pos_to_pos_distance(new_pos, pos);
      for (j = 0, _ref = distance_list.length; 0 <= _ref ? j < _ref : j > _ref; 0 <= _ref ? j++ : j--) {
        if (dis < distance_list[j]) break;
      }
      ordered_list.splice(j, 0, i);
      distance_list.splice(j, 0, dis);
    }
    for (_j = 0, _len2 = ordered_list.length; _j < _len2; _j++) {
      i = ordered_list[_j];
      w = Widget.look_up(i);
      if (!(w != null)) continue;
      old_pos = load_position(w.id);
      new_pos = coord_to_pos([old_pos.x + coord_x_shift, old_pos.y + coord_y_shift], [1, 1]);
      if (new_pos.x < 0 || new_pos.y < 0 || new_pos.x >= cols || new_pos.y >= rows) {
        continue;
      }
      move_to_somewhere(w, new_pos);
    }
    update_selected_item_drag_image();
  };

  selected_copy_to_clipboard = function() {
    var i, tmp_list, _i, _len;
    tmp_list = [];
    for (_i = 0, _len = selected_item.length; _i < _len; _i++) {
      i = selected_item[_i];
      tmp_list.push(i);
    }
    return alert("copy " + tmp_list.length + " file(s) to clipboard");
  };

  selected_cut_to_clipboard = function() {
    var i, tmp_list, _i, _len;
    tmp_list = [];
    for (_i = 0, _len = selected_item.length; _i < _len; _i++) {
      i = selected_item[_i];
      tmp_list.push(i);
    }
    return alert("cut " + tmp_list.length + " file(s) to clipboard");
  };

  paste_from_clipboard = function() {
    return alert("paste file(s) from clipboard");
  };

  item_dragstart_handler = function(widget, evt) {
    var all_selected_items, i, x, y, _ref;
    if (selected_item.length > 0) {
      all_selected_items = selected_item[0];
      for (i = 1, _ref = selected_item.length; i < _ref; i += 1) {
        all_selected_items += "\n" + selected_item[i];
      }
      evt.dataTransfer.setData("text/deepin_id_list", all_selected_items);
      evt.dataTransfer.effectAllowed = "moveCopy";
    }
    x = evt.x - drag_start.x * i_width;
    y = evt.y - drag_start.y * i_height;
    echo("setDragImage " + drag_start.x + "," + drag_start.y);
    return evt.dataTransfer.setDragImage(drag_image, x, y);
  };

  set_item_selected = function(w, top) {
    var _ref;
    if (top == null) top = false;
    if (w.selected === false) {
      w.item_selected();
      if (top === true) {
        selected_item.unshift(w.id);
      } else {
        selected_item.push(w.id);
      }
      if (last_widget !== w.id) {
        if (last_widget) {
          if ((_ref = Widget.look_up(last_widget)) != null) _ref.item_blur();
        }
        last_widget = w.id;
        w.item_focus();
      }
    }
  };

  cancel_item_selected = function(w) {
    var i, ret;
    ret = false;
    i = selected_item.indexOf(w.id);
    if (i >= 0) {
      selected_item.splice(i, 1);
      w.item_normal();
      ret = true;
      if (last_widget === w.id) {
        w.item_blur();
        last_widget = "";
      }
    }
    return ret;
  };

  cancel_all_selected_stats = function(clear_last) {
    var i, _i, _len, _ref, _ref2;
    if (clear_last == null) clear_last = true;
    for (_i = 0, _len = selected_item.length; _i < _len; _i++) {
      i = selected_item[_i];
      if ((_ref = Widget.look_up(i)) != null) _ref.item_normal();
    }
    selected_item.splice(0);
    if (clear_last && last_widget) {
      if ((_ref2 = Widget.look_up(last_widget)) != null) _ref2.item_blur();
      last_widget = "";
    }
  };

  update_selected_stats = function(w, evt) {
    var end_pos, i_pos, key, last_one_id, n, ret, start_pos, val, _i, _j, _len, _len2;
    if (evt.ctrlKey) {
      if (evt.type === "mousedown" || evt.type === "contextmenu") {
        if (w.selected === true) {
          cancel_item_selected(w);
        } else {
          set_item_selected(w);
        }
      }
    } else if (evt.shiftKey) {
      if (evt.type === "mousedown" || evt.type === "contextmenu") {
        if (selected_item.length > 1) {
          last_one_id = selected_item[selected_item.length - 1];
          selected_item.splice(selected_item.length - 1, 1);
          cancel_all_selected_stats(false);
          selected_item.push(last_one_id);
        }
        if (selected_item.length === 1) {
          end_pos = coord_to_pos(pixel_to_coord(evt.clientX, evt.clientY), [1, 1]);
          start_pos = load_position(Widget.look_up(selected_item[0]).id);
          ret = compare_pos_top_left(start_pos, end_pos);
          if (ret < 0) {
            for (_i = 0, _len = all_item.length; _i < _len; _i++) {
              key = all_item[_i];
              val = Widget.look_up(key);
              i_pos = load_position(val.id);
              if (compare_pos_top_left(end_pos, i_pos) >= 0 && compare_pos_top_left(start_pos, i_pos) < 0) {
                set_item_selected(val, true);
              }
            }
          } else if (ret === 0) {
            cancel_item_selected(selected_item[0]);
          } else {
            for (_j = 0, _len2 = all_item.length; _j < _len2; _j++) {
              key = all_item[_j];
              val = Widget.look_up(key);
              i_pos = load_position(val.id);
              if (compare_pos_top_left(start_pos, i_pos) > 0 && compare_pos_top_left(end_pos, i_pos) <= 0) {
                set_item_selected(val, true);
              }
            }
          }
        } else {
          set_item_selected(w);
        }
      }
    } else {
      n = selected_item.indexOf(w.id);
      if (evt.type === "mousedown" || evt.type === "contextmenu") {
        if (n < 0) {
          cancel_all_selected_stats(false);
          set_item_selected(w);
        }
      } else if (evt.type === "click") {
        if (n >= 0) {
          selected_item.splice(n, 1);
          cancel_all_selected_stats(false);
          selected_item.push(w.id);
          last_widget = w.id;
        }
      }
    }
    update_selected_item_drag_image();
  };

  update_selected_item_drag_image = function() {
    var bottom_right, drag_draw_delay_timer, i, line_number, line_text, m, n, pos, rest_text, start_x, start_y, top_left, w, _i, _j, _len, _len2, _ref;
    drag_draw_delay_timer = -1;
    if (selected_item.length === 0) return;
    pos = load_position(selected_item[0]);
    top_left = {
      x: cols - 1,
      y: rows - 1
    };
    bottom_right = {
      x: 0,
      y: 0
    };
    for (_i = 0, _len = selected_item.length; _i < _len; _i++) {
      i = selected_item[_i];
      pos = load_position(i);
      if (top_left.x > pos.x) top_left.x = pos.x;
      if (bottom_right.x < pos.x) bottom_right.x = pos.x;
      if (top_left.y > pos.y) top_left.y = pos.y;
      if (bottom_right.y < pos.y) bottom_right.y = pos.y;
    }
    if (top_left.x > bottom_right.x) top_left.x = bottom_right.x;
    if (top_left.y > bottom_right.y) top_left.y = bottom_right.y;
    drag_canvas.width = (bottom_right.x - top_left.x + 1) * i_width;
    drag_canvas.height = (bottom_right.y - top_left.y + 1) * i_height;
    if (!context) context = drag_canvas.getContext('2d');
    for (_j = 0, _len2 = selected_item.length; _j < _len2; _j++) {
      i = selected_item[_j];
      w = Widget.look_up(i);
      if (!(w != null)) continue;
      pos = load_position(i);
      pos.x -= top_left.x;
      pos.y -= top_left.y;
      start_x = pos.x * i_width;
      start_y = pos.y * i_height;
      context.shadowColor = "rgba(0, 0, 0, 0)";
      context.drawImage(w.item_icon, start_x + 22, start_y);
      context.shadowOffsetX = 1;
      context.shadowOffsetY = 1;
      context.shadowColor = "rgba(0, 0, 0, 1.0)";
      context.shadowBlur = 1.5;
      context.font = "bold small san-serif";
      context.fillStyle = "rgba(255, 255, 255, 1.0)";
      context.textAlign = "center";
      rest_text = w.element.innerText;
      line_number = 0;
      while (rest_text.length > 0) {
        if (rest_text.length < 10) {
          n = rest_text.length;
        } else {
          n = 10;
        }
        m = context.measureText(rest_text.substr(0, n)).width;
        if (m === 90) {
          pass;
        } else if (m > 90) {
          --n;
          while (n > 0 && context.measureText(rest_text.substr(0, n)).width > 90) {
            --n;
          }
        } else {
          ++n;
          while (n <= rest_text.length && context.measureText(rest_text.substr(0, n)).width < 90) {
            ++n;
          }
        }
        line_text = rest_text.substr(0, n);
        rest_text = rest_text.substr(n);
        context.fillText(line_text, start_x + 46, start_y + 64 + line_number * 14, 90);
        ++line_number;
      }
    }
    return _ref = [top_left.x, top_left.y], drag_start.x = _ref[0], drag_start.y = _ref[1], _ref;
  };

  build_selected_items_menu = function() {
    var menu;
    menu = [];
    menu.push([1, _("Open")]);
    menu.push([]);
    menu.push([3, _("cut")]);
    menu.push([4, _("copy")]);
    menu.push([]);
    if (selected_item.length > 1) {
      menu.push([6, "-" + _("Rename")]);
    } else {
      menu.push([6, _("Rename")]);
    }
    menu.push([9, _("Delete")]);
    menu.push([]);
    menu.push([10, _("Properties")]);
    return menu;
  };

  open_selected_items = function() {
    var i, _i, _len, _ref, _results;
    _results = [];
    for (_i = 0, _len = selected_item.length; _i < _len; _i++) {
      i = selected_item[_i];
      _results.push((_ref = Widget.look_up(i)) != null ? _ref.item_exec() : void 0);
    }
    return _results;
  };

  delete_selected_items = function() {
    var i, tmp, _i, _len;
    tmp = [];
    for (_i = 0, _len = selected_item.length; _i < _len; _i++) {
      i = selected_item[_i];
      tmp.push(i);
    }
    return DCore.Desktop.item_delete(tmp);
  };

  show_selected_items_Properties = function() {
    var i, tmp, w, _i, _len;
    tmp = [];
    for (_i = 0, _len = selected_item.length; _i < _len; _i++) {
      i = selected_item[_i];
      w = Widget.look_up(i);
      if (w != null) tmp.push("file://" + (w.get_path()));
    }
    return s_nautilus.ShowItemProperties_sync(tmp, '');
  };

  gird_left_mousedown = function(evt) {
    if (evt.ctrlKey === false && evt.shiftKey === false) {
      return cancel_all_selected_stats();
    }
  };

  grid_right_click = function(evt) {
    if (evt.ctrlKey === false && evt.shiftKey === false) {
      return cancel_all_selected_stats();
    }
  };

  grid_do_itemselected = function(evt) {
    switch (evt.id) {
      case 11:
        return menu_sort_desktop_item_by_name();
      case 12:
        return menu_sort_desktop_item_by_mtime();
      case 3:
        return DCore.Desktop.run_terminal();
      case 4:
        return paste_from_clipboard();
      case 5:
        return DCore.Desktop.run_deepin_settings("individuation");
      case 6:
        return DCore.Desktop.run_deepin_settings("display");
      default:
        return echo("not implemented function " + evt.id + "," + evt.title);
    }
  };

  create_item_grid = function() {
    div_grid = document.createElement("div");
    div_grid.setAttribute("id", "item_grid");
    document.body.appendChild(div_grid);
    update_gird_position(s_offset_x, s_offset_y, s_width, s_height);
    init_grid_drop();
    div_grid.parentElement.addEventListener("mousedown", gird_left_mousedown);
    div_grid.parentElement.addEventListener("contextmenu", grid_right_click);
    div_grid.parentElement.addEventListener("itemselected", grid_do_itemselected);
    div_grid.parentElement.contextMenu = gm;
    sel = new Mouse_Select_Area_box(div_grid.parentElement);
    drag_canvas = document.createElement("canvas");
    return drag_image = document.createElement("img");
  };

  ItemGrid = (function() {

    function ItemGrid(parentElement) {
      this._parent_element = parentElement;
      this._workarea_width = 0;
      this._workarea_height = 0;
      this._offset_x = 0;
      this._offset_y = 0;
    }

    return ItemGrid;

  })();

  Mouse_Select_Area_box = (function() {

    function Mouse_Select_Area_box(parentElement) {
      this.destory = __bind(this.destory, this);
      this.mouseup_event = __bind(this.mouseup_event, this);
      this.mousemove_event = __bind(this.mousemove_event, this);
      this.mousedown_event = __bind(this.mousedown_event, this);      this.parent_element = parentElement;
      this.element = document.createElement("div");
      this.element.setAttribute("id", "mouse_select_area_box");
      this.element.style.border = "1px solid #eee";
      this.element.style.backgroundColor = "rgba(167,167,167,0.5)";
      this.element.style.zIndex = "30";
      this.element.style.position = "absolute";
      this.element.style.visibility = "hidden";
      this.parent_element.appendChild(this.element);
      this.parent_element.addEventListener("mousedown", this.mousedown_event);
      this.last_effect_item = new Array;
    }

    Mouse_Select_Area_box.prototype.mousedown_event = function(evt) {
      evt.preventDefault();
      if (evt.button === 0) {
        this.parent_element.addEventListener("mousemove", this.mousemove_event);
        this.parent_element.addEventListener("mouseup", this.mouseup_event);
        this.start_point = evt;
        this.start_pos = coord_to_pos(pixel_to_coord(evt.clientX - s_offset_x, evt.clientY - s_offset_y), [1, 1]);
        this.last_pos = this.start_pos;
      }
    };

    Mouse_Select_Area_box.prototype.mousemove_event = function(evt) {
      var effect_item, i, item_pos, n, new_pos, pos_a, pos_b, sel_list, sh, sl, st, sw, temp_list, w, _i, _j, _k, _l, _len, _len2, _len3, _len4, _len5, _len6, _m, _n, _ref, _ref2;
      evt.preventDefault();
      sl = Math.min(Math.max(Math.min(this.start_point.clientX, evt.clientX), s_offset_x), s_offset_x + s_width);
      st = Math.min(Math.max(Math.min(this.start_point.clientY, evt.clientY), s_offset_y), s_offset_y + s_height);
      sw = Math.min(Math.abs(evt.clientX - this.start_point.clientX), s_width - sl);
      sh = Math.min(Math.abs(evt.clientY - this.start_point.clientY), s_height - st);
      this.element.style.left = "" + sl + "px";
      this.element.style.top = "" + st + "px";
      this.element.style.width = "" + sw + "px";
      this.element.style.height = "" + sh + "px";
      this.element.style.visibility = "visible";
      new_pos = coord_to_pos(pixel_to_coord(evt.clientX - s_offset_x, evt.clientY - s_offset_y), [1, 1]);
      if (compare_pos_top_left(this.last_pos, new_pos) !== 0) {
        if (compare_pos_top_left(this.start_pos, new_pos) < 0) {
          pos_a = new_pos;
          pos_b = this.start_pos;
        } else {
          pos_a = this.start_pos;
          pos_b = new_pos;
        }
        effect_item = new Array;
        for (_i = 0, _len = all_item.length; _i < _len; _i++) {
          i = all_item[_i];
          w = Widget.look_up(i);
          if (!(w != null)) continue;
          item_pos = load_position(w.id);
          if (compare_pos_rect(pos_a, pos_b, item_pos) === true) {
            effect_item.push(i);
          }
        }
        temp_list = effect_item.concat();
        sel_list = this.last_effect_item.concat();
        if (temp_list.length > 0 && sel_list.length > 0) {
          for (i = _ref = temp_list.length - 1; i > -1; i += -1) {
            for (n = _ref2 = sel_list.length - 1; n > -1; n += -1) {
              if (temp_list[i] === sel_list[n]) {
                temp_list.splice(i, 1);
                sel_list.splice(n, 1);
                break;
              }
            }
          }
        }
        if (evt.ctrlKey === true) {
          for (_j = 0, _len2 = temp_list.length; _j < _len2; _j++) {
            i = temp_list[_j];
            w = Widget.look_up(i);
            if (!(w != null)) {
              continue;
            } else if (w.selected === false) {
              set_item_selected(w);
            } else {
              cancel_item_selected(w);
            }
          }
          for (_k = 0, _len3 = sel_list.length; _k < _len3; _k++) {
            i = sel_list[_k];
            w = Widget.look_up(i);
            if (!(w != null)) {
              continue;
            } else if (w.selected === false) {
              set_item_selected(w);
            } else {
              cancel_item_selected(w);
            }
          }
        } else if (evt.shiftKey === true) {
          for (_l = 0, _len4 = temp_list.length; _l < _len4; _l++) {
            i = temp_list[_l];
            w = Widget.look_up(i);
            if (!(w != null)) continue;
            if (w.selected === false) set_item_selected(w);
          }
        } else {
          for (_m = 0, _len5 = temp_list.length; _m < _len5; _m++) {
            i = temp_list[_m];
            w = Widget.look_up(i);
            if (!(w != null)) continue;
            if (w.selected === false) set_item_selected(w);
          }
          for (_n = 0, _len6 = sel_list.length; _n < _len6; _n++) {
            i = sel_list[_n];
            w = Widget.look_up(i);
            if (!(w != null)) continue;
            if (w.selected === true) cancel_item_selected(w);
          }
        }
        this.last_pos = new_pos;
        this.last_effect_item = effect_item;
        if (temp_list.length > 0 || sel_list.length > 0) {
          update_selected_item_drag_image();
        }
      }
    };

    Mouse_Select_Area_box.prototype.mouseup_event = function(evt) {
      evt.preventDefault();
      this.parent_element.removeEventListener("mousemove", this.mousemove_event);
      this.parent_element.removeEventListener("mouseup", this.mouseup_event);
      this.element.style.visibility = "hidden";
      this.last_effect_item.splice(0);
    };

    Mouse_Select_Area_box.prototype.destory = function() {
      return this.parent_element.removeChild(this.element);
    };

    return Mouse_Select_Area_box;

  })();

  connect_default_signals = function() {
    DCore.signal_connect("item_update", do_item_update);
    DCore.signal_connect("item_delete", do_item_delete);
    DCore.signal_connect("item_rename", do_item_rename);
    DCore.signal_connect("workarea_changed", do_workarea_changed);
    return DCore.Desktop.notify_workarea_size();
  };

  do_item_delete = function(info) {
    var w;
    w = Widget.look_up(info.id);
    if (w != null) {
      cancel_item_selected(w);
      all_item.remove(info.id);
      w.destroy();
    }
    return update_selected_item_drag_image();
  };

  do_item_update = function(info) {
    var w;
    w = Widget.look_up(info.EntryPath);
    if (w != null) {
      return typeof w.item_update === "function" ? w.item_update(info.Icon) : void 0;
    } else {
      w = create_item(info);
      if (w != null) {
        move_to_anywhere(w);
        return all_item.push(w.id);
      }
    }
  };

  do_item_rename = function(data) {
    var w;
    w = Widget.look_up(data.old_id);
    if (w != null) {
      cancel_item_selected(w);
      all_item.remove(info.id);
      w.destroy();
    }
    update_position(data.old_id, data.info.EntryPath);
    w = create_item(data.info);
    if (w != null) {
      move_to_anywhere(w);
      all_item.push(w.id);
    }
    return update_selected_item_drag_image();
  };

  do_workarea_changed = function(allo) {
    return update_gird_position(allo.x + 4, allo.y + 4, allo.width - 8, allo.height - 8);
  };

  MAX_ITEM_TITLE = 20;

  DLCLICK_INTERVAL = 200;

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

  cleanup_filename = function(str) {
    var new_str;
    new_str = str.replace(/\n|\//g, "");
    if (new_str === "." || new_str === "..") {
      return "";
    } else {
      return new_str;
    }
  };

  Item = (function(_super) {

    __extends(Item, _super);

    function Item(entry) {
      var el, info;
      this.entry = entry;
      this.item_complete_rename = __bind(this.item_complete_rename, this);
      this.item_rename_keypress = __bind(this.item_rename_keypress, this);
      this.event_stoppropagation = __bind(this.event_stoppropagation, this);
      this.item_rename = __bind(this.item_rename, this);
      this.hide_hover_box = __bind(this.hide_hover_box, this);
      this.show_hover_box = __bind(this.show_hover_box, this);
      this.hide_selected_box = __bind(this.hide_selected_box, this);
      this.show_selected_box = __bind(this.show_selected_box, this);
      this.item_exec = __bind(this.item_exec, this);
      this.item_update = __bind(this.item_update, this);
      this.do_click = __bind(this.do_click, this);
      this.do_mousedown = __bind(this.do_mousedown, this);
      this.do_mouseout = __bind(this.do_mouseout, this);
      this.do_mouseover = __bind(this.do_mouseover, this);
      this.id = DCore.DEntry.get_id(this.entry);
      this.selected = false;
      this.in_rename = false;
      this.clicked = false;
      this.delay_rename = -1;
      Item.__super__.constructor.apply(this, arguments);
      el = this.element;
      info = {
        x: 0,
        y: 0,
        width: 1,
        height: 1
      };
      el.draggable = true;
      this.item_icon = document.createElement("img");
      this.item_icon.src = DCore.DEntry.get_icon(this.entry);
      this.item_icon.draggable = false;
      el.appendChild(this.item_icon);
      this.item_name = document.createElement("div");
      this.item_name.className = "item_name";
      this.item_name.innerText = shorten_text(DCore.DEntry.get_name(this.entry), MAX_ITEM_TITLE);
      el.appendChild(this.item_name);
    }

    Item.prototype.get_name = function() {
      return DCore.DEntry.get_name(this.entry);
    };

    Item.prototype.get_path = function() {
      return DCore.DEntry.get_path(this.entry);
    };

    Item.prototype.get_mtime = function() {
      return DCore.DEntry.get_mtime(this.entry);
    };

    Item.prototype.do_mouseover = function(evt) {
      return this.show_hover_box();
    };

    Item.prototype.do_mouseout = function(evt) {
      return this.hide_hover_box();
    };

    Item.prototype.do_mousedown = function(evt) {
      evt.stopPropagation();
      if (evt.button === 0) update_selected_stats(this, evt);
      return false;
    };

    Item.prototype.do_click = function(evt) {
      var _this = this;
      evt.stopPropagation();
      if (this.clicked === false) {
        this.clicked = true;
        update_selected_stats(this, evt);
      } else {
        if (evt.srcElement.className === "item_name") {
          if (this.delay_rename === -1) {
            this.delay_rename = setTimeout(function() {
              return _this.item_rename();
            }, 200);
          }
        } else {
          if (this.in_rename) {
            this.item_complete_rename(true);
          } else {
            update_selected_stats(this, evt);
          }
        }
      }
      return false;
    };

    Item.prototype.do_rightclick = function(evt) {
      evt.stopPropagation();
      if (this.selected === false) return update_selected_stats(this, evt);
    };

    Item.prototype.do_dblclick = function(evt) {
      if (this.delay_rename !== -1) {
        clearTimeout(this.delay_rename);
        this.delay_rename = -1;
      }
      if (this.in_rename) this.item_complete_rename(false);
      if (evt.ctrlKey === true) return;
      return this.item_exec();
    };

    Item.prototype.item_update = function(icon) {
      return this.item_icon.src = "" + icon;
    };

    Item.prototype.item_exec = function() {
      return DCore.DEntry.launch(this.entry, []);
    };

    Item.prototype.item_selected = function() {
      this.selected = true;
      return this.show_selected_box();
    };

    Item.prototype.item_normal = function() {
      this.selected = false;
      this.clicked = false;
      return this.hide_selected_box();
    };

    Item.prototype.item_focus = function() {
      return this.item_name.innerText = DCore.DEntry.get_name(this.entry);
    };

    Item.prototype.item_blur = function() {
      if (this.delay_rename !== -1) {
        clearTimeout(this.delay_rename);
        this.delay_rename = -1;
      }
      if (this.in_rename) this.item_complete_rename();
      return this.item_name.innerText = shorten_text(DCore.DEntry.get_name(this.entry), MAX_ITEM_TITLE);
    };

    Item.prototype.show_selected_box = function() {
      return this.element.className += " item_selected";
    };

    Item.prototype.hide_selected_box = function() {
      return this.element.className = this.element.className.replace(/\ item_selected/g, "");
    };

    Item.prototype.show_hover_box = function() {
      return this.element.className += " item_hover";
    };

    Item.prototype.hide_hover_box = function() {
      return this.element.className = this.element.className.replace(/\ item_hover/g, "");
    };

    Item.prototype.item_rename = function() {
      echo("item_rename");
      this.delay_rename = -1;
      if (this.selected === false) return;
      if (this.in_rename === false) {
        this.element.draggable = false;
        this.item_name.contentEditable = "true";
        this.item_name.className = "item_renaming";
        this.item_name.focus();
        this.item_name.addEventListener("mousedown", this.event_stoppropagation);
        this.item_name.addEventListener("click", this.event_stoppropagation);
        this.item_name.addEventListener("dblclick", this.event_stoppropagation);
        this.item_name.addEventListener("keypress", this.item_rename_keypress);
        this.in_rename = true;
      }
    };

    Item.prototype.event_stoppropagation = function(evt) {
      return evt.stopPropagation();
    };

    Item.prototype.item_rename_keypress = function(evt) {
      evt.stopPropagation();
      switch (evt.keyCode) {
        case 13:
          evt.preventDefault();
          this.item_complete_rename(true);
          break;
        case 27:
          evt.preventDefault();
          this.item_complete_rename(false);
          break;
        case 47:
          evt.preventDefault();
      }
    };

    Item.prototype.item_complete_rename = function(modify) {
      var new_name;
      if (modify == null) modify = true;
      this.element.draggable = true;
      this.item_name.contentEditable = "false";
      this.item_name.className = "item_name";
      this.item_name.removeEventListener("mousedown", this.event_stoppropagation);
      this.item_name.removeEventListener("click", this.event_stoppropagation);
      this.item_name.removeEventListener("dblclick", this.event_stoppropagation);
      this.item_name.removeEventListener("keypress", this.item_rename_keypress);
      new_name = cleanup_filename(this.item_name.innerText);
      if (modify === true && new_name.length > 0 && new_name !== this.get_name()) {
        DCore.DEntry.set_name(this.entry, new_name);
      }
      if (this.delay_rename > 0) {
        clearTimeout(this.delay_rename);
        this.delay_rename = 0;
      }
      this.in_rename = false;
      return this.item_focus();
    };

    Item.prototype.destroy = function() {
      var info;
      info = load_position(this.id);
      clear_occupy(info);
      return Item.__super__.destroy.apply(this, arguments);
    };

    Item.prototype.move = function(x, y) {
      var style;
      style = this.element.style;
      style.position = "absolute";
      style.left = x;
      return style.top = y;
    };

    return Item;

  })(Widget);

  DesktopEntry = (function(_super) {

    __extends(DesktopEntry, _super);

    function DesktopEntry() {
      this.do_itemselected = __bind(this.do_itemselected, this);
      this.do_dragleave = __bind(this.do_dragleave, this);
      this.do_dragover = __bind(this.do_dragover, this);
      this.do_dragenter = __bind(this.do_dragenter, this);
      this.do_drop = __bind(this.do_drop, this);
      this.do_dragend = __bind(this.do_dragend, this);
      this.do_dragstart = __bind(this.do_dragstart, this);      this.in_count = 0;
      DesktopEntry.__super__.constructor.apply(this, arguments);
    }

    DesktopEntry.prototype.do_dragstart = function(evt) {
      evt.stopPropagation();
      item_dragstart_handler(this, evt);
    };

    DesktopEntry.prototype.do_dragend = function(evt) {
      evt.stopPropagation();
      evt.preventDefault();
      if (evt.dataTransfer.dropEffect === "move") {
        drag_update_selected_pos(this, evt);
      }
    };

    DesktopEntry.prototype.do_drop = function(evt) {
      evt.preventDefault();
      evt.stopPropagation();
      if (this.selected === false) {
        this.hide_hover_box();
        return this.in_count = 0;
      }
    };

    DesktopEntry.prototype.do_dragenter = function(evt) {
      var all_selected_items, files;
      evt.stopPropagation();
      if (this.selected === false) {
        ++this.in_count;
        if (this.in_count === 1) this.show_hover_box();
      }
      all_selected_items = evt.dataTransfer.getData("text/deepin_id_list");
      files = all_selected_items.split("\n");
      if (files.indexOf(this.id) >= 0) {
        evt.dataTransfer.dropEffect = "none";
      } else {
        evt.dataTransfer.dropEffect = "link";
      }
      echo("do_dragenter " + evt.dataTransfer.dropEffect);
    };

    DesktopEntry.prototype.do_dragover = function(evt) {
      var all_selected_items, files;
      evt.preventDefault();
      evt.stopPropagation();
      all_selected_items = evt.dataTransfer.getData("text/deepin_id_list");
      files = all_selected_items.split("\n");
      if (files.indexOf(this.id) >= 0) {
        evt.dataTransfer.dropEffect = "none";
      } else {
        evt.dataTransfer.dropEffect = "link";
      }
      echo("do_dragover " + evt.dataTransfer.dropEffect);
    };

    DesktopEntry.prototype.do_dragleave = function(evt) {
      evt.stopPropagation();
      if (this.selected === false) {
        --this.in_count;
        if (this.in_count === 0) return this.hide_hover_box();
      }
    };

    DesktopEntry.prototype.do_buildmenu = function() {
      return build_selected_items_menu();
    };

    DesktopEntry.prototype.do_itemselected = function(evt) {
      switch (evt.id) {
        case 1:
          return open_selected_items();
        case 3:
          return selected_cut_to_clipboard();
        case 4:
          return selected_copy_to_clipboard();
        case 6:
          return this.item_rename();
        case 9:
          return delete_selected_items();
        case 10:
          return show_selected_items_Properties();
        default:
          return echo("menu clicked:id=" + env.id + " title=" + env.title);
      }
    };

    return DesktopEntry;

  })(Item);

  Folder = (function(_super) {

    __extends(Folder, _super);

    function Folder() {
      this.hide_pop_block = __bind(this.hide_pop_block, this);
      this.fill_pop_block = __bind(this.fill_pop_block, this);
      this.reflesh_pop_block = __bind(this.reflesh_pop_block, this);
      this.show_pop_block = __bind(this.show_pop_block, this);
      this.do_dragover = __bind(this.do_dragover, this);
      this.do_dragenter = __bind(this.do_dragenter, this);
      this.do_drop = __bind(this.do_drop, this);
      this.do_dragstart = __bind(this.do_dragstart, this);
      this.do_dblclick = __bind(this.do_dblclick, this);
      this.do_click = __bind(this.do_click, this);      Folder.__super__.constructor.apply(this, arguments);
      if (!(this.exec != null)) this.exec = "gvfs-open \"" + this.id + "\"";
      this.div_pop = null;
      this.show_pop = false;
    }

    Folder.prototype.do_click = function(evt) {
      Folder.__super__.do_click.apply(this, arguments);
      if (evt.shiftKey === false && evt.ctrlKey === false) {
        if (this.show_pop === false) return this.show_pop_block();
      }
    };

    Folder.prototype.do_dblclick = function(evt) {
      if (this.show_pop === true) this.hide_pop_block();
      return Folder.__super__.do_dblclick.apply(this, arguments);
    };

    Folder.prototype.do_dragstart = function(evt) {
      if (this.show_pop === true) this.hide_pop_block();
      return Folder.__super__.do_dragstart.apply(this, arguments);
    };

    Folder.prototype.do_drop = function(evt) {
      var all_selected_items, file, files, i, _i, _len;
      Folder.__super__.do_drop.apply(this, arguments);
      all_selected_items = evt.dataTransfer.getData("text/deepin_id_list");
      files = all_selected_items.split("\n");
      for (_i = 0, _len = files.length; _i < _len; _i++) {
        file = files[_i];
        i = decodeURI(file);
        this.move_in(i);
      }
    };

    Folder.prototype.do_dragenter = function(evt) {
      var all_selected_items, files;
      evt.stopPropagation();
      if (this.selected === false) {
        ++this.in_count;
        if (this.in_count === 1) this.show_hover_box();
      }
      all_selected_items = evt.dataTransfer.getData("text/deepin_id_list");
      files = all_selected_items.split("\n");
      if (files.indexOf(this.id) >= 0) {
        evt.dataTransfer.dropEffect = "none";
      } else {
        evt.dataTransfer.dropEffect = "move";
      }
      echo("do_dragenter " + evt.dataTransfer.dropEffect);
    };

    Folder.prototype.do_dragover = function(evt) {
      var all_selected_items, files;
      evt.preventDefault();
      evt.stopPropagation();
      all_selected_items = evt.dataTransfer.getData("text/deepin_id_list");
      files = all_selected_items.split("\n");
      if (files.indexOf(this.id) >= 0) {
        evt.dataTransfer.dropEffect = "none";
      } else {
        evt.dataTransfer.dropEffect = "move";
      }
      echo("do_dragover " + evt.dataTransfer.dropEffect);
    };

    Folder.prototype.item_update = function(icon) {
      if (this.show_pop === true) this.reflesh_pop_block();
      return Folder.__super__.item_update.apply(this, arguments);
    };

    Folder.prototype.item_blur = function() {
      if (this.div_pop !== null) this.hide_pop_block();
      return Folder.__super__.item_blur.apply(this, arguments);
    };

    Folder.prototype.destroy = function() {
      if (this.div_pop !== null) this.hide_pop_block();
      return Folder.__super__.destroy.apply(this, arguments);
    };

    Folder.prototype.show_pop_block = function() {
      var e, _i, _len, _ref;
      if (this.selected === false) return;
      if (this.div_pop !== null) return;
      this.sub_items = {};
      this.sub_items_count = 0;
      _ref = DCore.DEntry.list_files(this.entry);
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        e = _ref[_i];
        this.sub_items[DCore.DEntry.get_id(e)] = e;
        ++this.sub_items_count;
      }
      if (this.sub_items_count === 0) return;
      this.div_pop = document.createElement("div");
      this.div_pop.setAttribute("id", "pop_grid");
      document.body.appendChild(this.div_pop);
      this.div_pop.addEventListener("mousedown", this.event_stoppropagation);
      this.show_pop = true;
      return this.fill_pop_block();
    };

    Folder.prototype.reflesh_pop_block = function() {
      var e, i, _i, _j, _k, _len, _len2, _len3, _ref, _ref2, _ref3;
      _ref = this.div_pop.getElementsByTagName("ul");
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        i = _ref[_i];
        i.parentElement.removeChild(i);
      }
      _ref2 = this.div_pop.getElementsByTagName("div");
      for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
        i = _ref2[_j];
        if (i.id === "pop_downarrow" || i.id === "pop_uparrow") {
          i.parentElement.removeChild(i);
        }
      }
      this.sub_items = {};
      this.sub_items_count = 0;
      _ref3 = DCore.DEntry.list_files(this.entry);
      for (_k = 0, _len3 = _ref3.length; _k < _len3; _k++) {
        e = _ref3[_k];
        this.sub_items[DCore.DEntry.get_id(e)] = e;
        ++this.sub_items_count;
      }
      if (this.sub_items_count === 0) {
        return this.hide_pop_block();
      } else {
        return this.fill_pop_block();
      }
    };

    Folder.prototype.fill_pop_block = function() {
      var arrow, arrow_pos, col, e, ele, ele_ul, i, n, p, s, _ref;
      ele_ul = document.createElement("ul");
      ele_ul.setAttribute("title", this.id);
      this.div_pop.appendChild(ele_ul);
      _ref = this.sub_items;
      for (i in _ref) {
        e = _ref[i];
        ele = document.createElement("li");
        ele.setAttribute('id', i);
        ele.draggable = true;
        s = document.createElement("img");
        s.src = DCore.DEntry.get_icon(e);
        ele.appendChild(s);
        s = document.createElement("div");
        s.innerText = shorten_text(DCore.DEntry.get_name(e), MAX_ITEM_TITLE);
        ele.appendChild(s);
        ele.addEventListener('mousedown', function(evt) {
          return evt.stopPropagation();
        });
        ele.addEventListener('click', function(evt) {
          return evt.stopPropagation();
        });
        ele.addEventListener('dragstart', function(evt) {
          evt.stopPropagation();
          evt.dataTransfer.setData("text/uri-list", "file://" + this.id);
          return evt.dataTransfer.effectAllowed = "moveCopy";
        });
        ele.addEventListener('dragend', function(evt) {
          return evt.stopPropagation();
        });
        ele.addEventListener('dblclick', function(evt) {
          var w;
          w = Widget.look_up(this.parentElement.title);
          if (w != null) e = w.sub_items[this.id];
          if (e != null) DCore.DEntry.launch(e, []);
          if (w != null) return w.hide_pop_block();
        });
        ele_ul.appendChild(ele);
      }
      if (this.sub_items_count <= 3) {
        col = this.sub_items_count;
      } else if (this.sub_items_count <= 6) {
        col = 3;
      } else if (this.sub_items_count <= 12) {
        col = 4;
      } else if (this.sub_items_count <= 20) {
        col = 5;
      } else {
        col = 6;
      }
      if (this.sub_items_count > 24) {
        this.div_pop.style.width = "" + (col * i_width + 10) + "px";
      } else {
        this.div_pop.style.width = "" + (col * i_width + 2) + "px";
      }
      arrow = document.createElement("div");
      n = Math.ceil(this.sub_items_count / col);
      if (n > 4) n = 4;
      n = n * i_height + 20;
      if (s_height - this.element.offsetTop > n) {
        this.div_pop.style.top = "" + (this.element.offsetTop + this.element.offsetHeight + 20) + "px";
        arrow_pos = false;
      } else {
        this.div_pop.style.top = "" + (this.element.offsetTop - n - 16) + "px";
        arrow_pos = true;
      }
      n = (col * i_width) / 2;
      p = this.element.offsetLeft + this.element.offsetWidth / 2 - 10;
      if (p < n) {
        this.div_pop.style.left = "0";
        arrow.style.left = "" + p + "px";
      } else if (p + n > s_width) {
        this.div_pop.style.left = "" + (s_width - 2 * n) + "px";
        arrow.style.right = "" + (s_width - p) + "px";
      } else {
        this.div_pop.style.left = "" + (p - n) + "px";
        arrow.style.left = "" + n + "px";
      }
      if (arrow_pos === true) {
        arrow.setAttribute("id", "pop_downarrow");
        return this.div_pop.appendChild(arrow);
      } else {
        arrow.setAttribute("id", "pop_uparrow");
        return this.div_pop.insertBefore(arrow, this.div_pop.firstChild);
      }
    };

    Folder.prototype.hide_pop_block = function() {
      var _ref;
      if (this.div_pop != null) {
        this.sub_items = {};
        if ((_ref = this.div_pop.parentElement) != null) {
          _ref.removeChild(this.div_pop);
        }
        delete this.div_pop;
        this.div_pop = null;
      }
      return this.show_pop = false;
    };

    Folder.prototype.move_in = function(c_path) {
      var p;
      p = c_path.replace("file://", "");
      return DCore.run_command2("mv", p, this.get_path());
    };

    return Folder;

  })(DesktopEntry);

  Application = (function(_super) {

    __extends(Application, _super);

    function Application() {
      Application.__super__.constructor.apply(this, arguments);
    }

    Application.prototype.do_drop = function(evt) {
      var all_are_apps, all_selected_items, f, files, tmp_list, w, _i, _len;
      Application.__super__.do_drop.apply(this, arguments);
      tmp_list = [];
      all_are_apps = true;
      all_selected_items = evt.dataTransfer.getData("text/deepin_id_list");
      files = all_selected_items.split("\n");
      for (_i = 0, _len = files.length; _i < _len; _i++) {
        f = files[_i];
        w = Widget.look_up(f);
        if (w != null) {
          if (w.constructor.name !== "Application") all_are_apps = false;
          tmp_list.push(f);
        }
      }
      if (all_are_apps === true) {
        tmp_list.push(this.id);
        alert("we should merge files here");
      } else {
        alert("we should run app to open these files");
      }
    };

    return Application;

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

  FILE_TYPE_APP = 0;

  FILE_TYPE_FILE = 1;

  FILE_TYPE_DIR = 2;

  create_item = function(entry) {
    var Id, Type, w;
    w = null;
    Id = DCore.DEntry.get_id(entry);
    Type = DCore.DEntry.get_type(entry);
    switch (Type) {
      case FILE_TYPE_APP:
        w = new Application(entry);
        break;
      case FILE_TYPE_FILE:
        w = new NormalFile(entry);
        break;
      case FILE_TYPE_DIR:
        w = new Folder(entry);
        break;
      default:
        echo("don't support type");
    }
    if (w != null) div_grid.appendChild(w.element);
    return w;
  };

  clear_desktop_items = function() {
    var i, _i, _len, _ref;
    for (_i = 0, _len = all_item.length; _i < _len; _i++) {
      i = all_item[_i];
      if ((_ref = Widget.look_up(i)) != null) _ref.destroy();
    }
    return all_item.splice(0);
  };

  load_desktop_all_items = function() {
    var e, w, _i, _len, _ref, _results;
    clear_desktop_items();
    _ref = DCore.Desktop.get_desktop_entries();
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      e = _ref[_i];
      w = create_item(e);
      if (w != null) {
        all_item.push(w.id);
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
