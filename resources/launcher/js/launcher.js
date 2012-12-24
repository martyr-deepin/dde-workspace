(function() {
  var $, $s, append_to_category, applications, assert, basename, build_menu, c, category_infos, create_category, create_element, create_img, create_item, do_workarea_changed, echo, find_drag_target, get_page_xy, grid, grid_load_category, grid_show_items, info, run_post, s_box, search, show_grid_selected, swap_element, _, _i, _j, _len, _len2, _ref, _ref2,
    __hasProp = Object.prototype.hasOwnProperty;

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

  applications = {};

  category_infos = [];

  create_item = function(info) {
    var el;
    el = document.createElement('div');
    el.setAttribute('class', 'item');
    el.id = info.ID;
    el.innerHTML = "    <img draggable=false src=" + info.Icon + " />    <div class=item_name> " + info.Name + "</div>    <div class=item_comment>" + info.Comment + "</div>    ";
    el.click_cb = function(e) {
      el.style.cursor = "wait";
      DCore.DEntry.launch(info.Core, []);
      return DCore.Launcher.exit_gui();
    };
    el.addEventListener('click', el.click_cb);
    return el;
  };

  _ref = DCore.Launcher.get_items();
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    info = _ref[_i];
    applications[info.ID] = create_item(info);
  }

  grid_show_items = function(items) {
    var i, _j, _len2, _results;
    grid.innerHTML = "";
    _results = [];
    for (_j = 0, _len2 = items.length; _j < _len2; _j++) {
      i = items[_j];
      _results.push(grid.appendChild(applications[i]));
    }
    return _results;
  };

  show_grid_selected = function(id) {
    var c, cns, _j, _len2, _results;
    cns = $s(".category_name");
    _results = [];
    for (_j = 0, _len2 = cns.length; _j < _len2; _j++) {
      c = cns[_j];
      if (id == c.getAttribute("cat_id")) {
        _results.push(c.setAttribute("class", "category_name category_selected"));
      } else {
        _results.push(c.setAttribute("class", "category_name"));
      }
    }
    return _results;
  };

  grid = $('#grid');

  grid_load_category = function(cat_id) {
    var key, value;
    show_grid_selected(cat_id);
    if (cat_id === -1) {
      grid.innerHTML = "";
      for (key in applications) {
        if (!__hasProp.call(applications, key)) continue;
        value = applications[key];
        grid.appendChild(value);
      }
      return;
    }
    if (category_infos[cat_id]) {
      info = category_infos[cat_id];
    } else {
      info = DCore.Launcher.get_items_by_category(cat_id);
      category_infos[cat_id] = info;
    }
    return grid_show_items(info);
  };

  do_workarea_changed = function(alloc) {
    var height;
    height = alloc.height;
    document.body.style.maxHeight = "" + height + "px";
    return $('#grid').style.maxHeight = "" + (height - 60) + "px";
  };

  DCore.signal_connect('workarea_changed', do_workarea_changed);

  DCore.Launcher.notify_workarea_size();

  create_category = function(info) {
    var el;
    el = document.createElement('div');
    el.setAttribute('class', 'category_name');
    el.setAttribute('cat_id', info.ID);
    el.innerHTML = "    <div>" + info.Name + "</div>    ";
    el.addEventListener('click', function(e) {
      return grid_load_category(info.ID);
    });
    return el;
  };

  append_to_category = function(cat) {
    return $('#category').appendChild(cat);
  };

  append_to_category(create_category({
    "ID": -1,
    "Name": _("All")
  }));

  $("#close").addEventListener("click", function() {
    return DCore.Launcher.exit_gui();
  });

  _ref2 = DCore.Launcher.get_categories();
  for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
    info = _ref2[_j];
    c = create_category(info);
    append_to_category(c);
  }

  grid_load_category(-1);

  basename = function(path) {
    return path.replace(/\\/g, '/').replace(/.*\//);
  };

  s_box = $('#s_box');

  search = function() {
    var k, key, ret;
    ret = [];
    key = s_box.value.toLowerCase();
    for (k in applications) {
      if (key === "") {
        ret.push(k);
      } else if (basename(k).toLowerCase().indexOf(key) >= 0) {
        ret.push(k);
      }
    }
    grid_show_items(ret);
    return ret;
  };

  s_box.addEventListener('input', s_box.blur());

  document.body.onkeypress = function(e) {
    switch (e.which) {
      case 27:
        if (s_box.value === "") {
          DCore.Launcher.exit_gui();
        } else {
          s_box.value = "";
        }
        break;
      case 8:
        s_box.value = s_box.value.substr(0, s_box.value.length - 1);
        break;
      case 13:
        $('#grid').children[0].click_cb();
        break;
      default:
        s_box.value += String.fromCharCode(e.which);
    }
    return search();
  };

}).call(this);
