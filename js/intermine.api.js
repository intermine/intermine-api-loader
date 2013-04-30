(function() {
var CSSLoader, JSLoader, Loader, load, root,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

root = this;

Loader = (function() {
  function Loader() {}

  Loader.prototype.getHead = function() {
    return document.getElementsByTagName('head')[0];
  };

  Loader.prototype.setCallback = function(tag, callback) {
    tag.onload = callback;
    return tag.onreadystatechange = function() {
      var state;

      state = tag.readyState;
      if (state === 'complete' || state === 'loaded') {
        tag.onreadystatechange = null;
        return root.setTimeout(callback, 0);
      }
    };
  };

  return Loader;

})();

JSLoader = (function(_super) {
  __extends(JSLoader, _super);

  function JSLoader(path, callback) {
    var script;

    script = document.createElement('script');
    script.src = path;
    script.type = 'text/javascript';
    if (callback) {
      this.setCallback(script, callback);
    }
    this.getHead().appendChild(script);
  }

  return JSLoader;

})(Loader);

CSSLoader = (function(_super) {
  __extends(CSSLoader, _super);

  function CSSLoader(path, callback) {
    var sheet;

    sheet = document.createElement('link');
    sheet.rel = 'stylesheet';
    sheet.type = 'text/css';
    sheet.href = path;
    if (callback) {
      this.setCallback(sheet, callback);
    }
    this.getHead().appendChild(sheet);
  }

  return CSSLoader;

})(Loader);

load = function(resources, type, cb) {
  var check, depends, key, obj, path, _ref;

  obj = {};
  for (key in resources) {
    _ref = resources[key], path = _ref.path, check = _ref.check, depends = _ref.depends;
    if (!path) {
      throw "Missing `path` for " + key;
    }
    if (check) {
      switch (typeof check) {
        case 'string':
          if ((root[check] != null) && (typeof root[check] === 'function' || 'object')) {
            console.log('already have', key);
            continue;
          }
          break;
        case 'function':
          if (check()) {
            continue;
          }
          break;
        default:
          throw "Misconfigured `check` for " + key;
      }
    }
    console.log('load', key);
  }
  return;
  return async.auto({
    'D': [
      'B', function(cb) {
        console.log('D');
        return setTimeout(cb, 1);
      }
    ],
    'B': function(cb) {
      console.log('B');
      return setTimeout(cb, 1);
    },
    'A': function(cb) {
      console.log('A');
      return setTimeout(cb, 1);
    },
    'C': [
      'A', 'B', function(cb) {
        console.log('C');
        return setTimeout(cb, 1);
      }
    ]
  });
};

root.intermine = root.intermine || {};

intermine.load = function(library, version, cb) {
  var i, key, name, o, path, resources, type, wait, _i, _len, _ref, _ref1;

  if (typeof version === 'function') {
    cb = version;
    version = 'latest';
  }
  if (typeof library === 'string') {
    if (intermine.resources[library] == null) {
      throw "Unknown library `" + library + "`";
    }
    if ((path = intermine.resources[library][version]) == null) {
      throw "Unknown `" + library + "` version " + version;
    }
    o = {};
    o["intermine." + library] = {
      'path': path
    };
    return load(o, 'js', cb);
  }
  if (library instanceof Array) {
    o = {
      'js': {},
      'css': {}
    };
    for (i in library) {
      _ref = library[i], name = _ref.name, path = _ref.path, type = _ref.type, wait = _ref.wait;
      if (!(path || type)) {
        throw 'Library `path` or `type` not provided';
      }
      if (type !== 'css' && type !== 'js') {
        throw "Library type `" + type + "` not recognized";
      }
      if (!name) {
        name = path.split('/').pop();
      }
      o[type][name] = {
        'path': path,
        'check': name
      };
      if (!!wait && i !== 0) {
        o[type][name].depends = [library[i - 1].name];
      }
    }
    library = o;
  }
  if (typeof library === 'object') {
    _ref1 = ['css', 'js'];
    for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
      key = _ref1[_i];
      if ((resources = library[key])) {
        load(resources, key, cb);
      }
    }
    return;
  }
  throw 'Unrecognized input';
};

intermine.load({
  'css': {
    'A': {
      'path': 'http://a'
    },
    'B': {
      'path': 'http://b'
    }
  },
  'js': {
    'A': {
      'path': 'http://a',
      'depends': ['B']
    },
    'B': {
      'path': 'http://b',
      'check': function() {
        return true;
      }
    },
    'C': {
      'path': 'http://c',
      'depends': ['A', 'B']
    }
  }
});

intermine.resources = {"widgets":{"latest":"http://cdn.intermine.org/js/intermine/widgets/latest/intermine.widgets.js","1.0.0":"http://cdn.intermine.org/js/intermine/widgets/1.0.0/intermine.widgets.js","1.1.0":"http://cdn.intermine.org/js/intermine/widgets/1.1.0/intermine.widgets.js","1.1.7":"http://cdn.intermine.org/js/intermine/widgets/1.1.7/intermine.widgets.js","1.1.8":"http://cdn.intermine.org/js/intermine/widgets/1.1.8/intermine.widgets.js","1.1.9":"http://cdn.intermine.org/js/intermine/widgets/1.1.9/intermine.widgets.js","1.1.10":"http://cdn.intermine.org/js/intermine/widgets/1.1.10/intermine.widgets.js","1.2.0":"http://cdn.intermine.org/js/intermine/widgets/1.2.0/intermine.widgets.js","1.2.1":"http://cdn.intermine.org/js/intermine/widgets/1.2.1/intermine.widgets.js","1.3.0":"http://cdn.intermine.org/js/intermine/widgets/1.3.0/intermine.widgets.js","1.4.0":"http://cdn.intermine.org/js/intermine/widgets/1.4.0/intermine.widgets.js","1.4.1":"http://cdn.intermine.org/js/intermine/widgets/1.4.1/intermine.widgets.js","1.4.2":"http://cdn.intermine.org/js/intermine/widgets/1.4.2/intermine.widgets.js","1.6.7":"http://cdn.intermine.org/js/intermine/widgets/1.6.7/intermine.widgets.js","1.6.8":"http://cdn.intermine.org/js/intermine/widgets/1.6.8/intermine.widgets.js","1.7.0":"http://cdn.intermine.org/js/intermine/widgets/1.7.0/intermine.widgets.js","1.7.3":"http://cdn.intermine.org/js/intermine/widgets/1.7.3/intermine.widgets.js","1.8.0":"http://cdn.intermine.org/js/intermine/widgets/1.8.0/intermine.widgets.js","1.8.1":"http://cdn.intermine.org/js/intermine/widgets/1.8.1/intermine.widgets.js","1.8.2":"http://cdn.intermine.org/js/intermine/widgets/1.8.2/intermine.widgets.js","1.8.3":"http://cdn.intermine.org/js/intermine/widgets/1.8.3/intermine.widgets.js","1.9.1":"http://cdn.intermine.org/js/intermine/widgets/1.9.1/intermine.widgets.js","1.10.0":"http://cdn.intermine.org/js/intermine/widgets/1.10.0/intermine.widgets.js","1.11.2":"http://cdn.intermine.org/js/intermine/widgets/1.11.2/intermine.widgets.js"},"report-widgets":{"latest":"http://cdn.intermine.org/js/intermine/report-widgets/latest/intermine.report-widgets.js","0.7.0":"http://cdn.intermine.org/js/intermine/report-widgets/0.7.0/intermine.report-widgets.js"}};
}).call(this);