(function() {
var CSSLoader, JSLoader, load, root;

root = this;

JSLoader = function(path, cb) {
  var script, setCallback;

  setCallback = function(tag, cb) {
    tag.onload = cb;
    return tag.onreadystatechange = function() {
      var state;

      state = tag.readyState;
      if (state === 'complete' || state === 'loaded') {
        tag.onreadystatechange = null;
        return root.setTimeout(cb, 0);
      }
    };
  };
  script = document.createElement('script');
  script.src = path;
  script.type = 'text/javascript';
  if (cb) {
    setCallback(script, cb);
  }
  return document.getElementsByTagName('head')[0].appendChild(script);
};

CSSLoader = function(path) {
  var sheet;

  sheet = document.createElement('link');
  sheet.rel = 'stylesheet';
  sheet.type = 'text/css';
  sheet.href = path;
  return document.getElementsByTagName('head')[0].appendChild(sheet);
};

load = function(resources, type, cb) {
  var check, dep, depends, key, obj, path, _ref;

  obj = {};
  for (key in resources) {
    _ref = resources[key], path = _ref.path, check = _ref.check, depends = _ref.depends;
    if (!path) {
      throw "Library `path` not provided for " + key;
    }
    if (check && typeof check === 'function') {
      if (check()) {
        continue;
      }
    }
    if ((root[key] != null) && (typeof root[key] === 'function' || 'object')) {
      console.log('already have', key);
      continue;
    }
    console.log('load', key);
    if (type === 'js' && depends && depends instanceof Array) {
      if (!(function() {
        var _i, _len, _results;

        _results = [];
        for (_i = 0, _len = depends.length; _i < _len; _i++) {
          dep = depends[_i];
          _results.push(resources[dep] != null);
        }
        return _results;
      })()) {
        throw "Unrecognized dependency `" + dep + "`";
      }
      obj[key] = depends.concat(function(cb) {
        return JSLoader(path, cb);
      });
    } else {
      obj[key] = function(cb) {
        return JSLoader(path, cb);
      };
    }
  }
  return async.auto(obj);
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
  'js': {
    'JSON': {
      'path': 'http://cdn.intermine.org/js/json3/3.2.2/json3.min.js'
    },
    'setImmediate': {
      'path': 'http://cdn.intermine.org/js/setImmediate/1.0.1/setImmediate.min.js',
      'check': function() {
        return true;
      }
    },
    'async': {
      'path': 'http://cdn.intermine.org/js/async/0.2.6/async.min.js',
      'depends': ['setImmediate']
    },
    'jQuery': {
      'path': 'http://cdn.intermine.org/js/jquery/1.7.2/jquery.min.js',
      'depends': ['JSON']
    },
    '_': {
      'path': 'http://cdn.intermine.org/js/underscore.js/1.3.3/underscore-min.js',
      'depends': ['JSON']
    },
    'Backbone': {
      'path': 'http://cdn.intermine.org/js/backbone.js/0.9.2/backbone-min.js',
      'depends': ['jQuery', '_']
    }
  }
});

intermine.resources = {"widgets":{"latest":"http://cdn.intermine.org/js/intermine/widgets/latest/intermine.widgets.js","1.0.0":"http://cdn.intermine.org/js/intermine/widgets/1.0.0/intermine.widgets.js","1.1.0":"http://cdn.intermine.org/js/intermine/widgets/1.1.0/intermine.widgets.js","1.1.7":"http://cdn.intermine.org/js/intermine/widgets/1.1.7/intermine.widgets.js","1.1.8":"http://cdn.intermine.org/js/intermine/widgets/1.1.8/intermine.widgets.js","1.1.9":"http://cdn.intermine.org/js/intermine/widgets/1.1.9/intermine.widgets.js","1.1.10":"http://cdn.intermine.org/js/intermine/widgets/1.1.10/intermine.widgets.js","1.2.0":"http://cdn.intermine.org/js/intermine/widgets/1.2.0/intermine.widgets.js","1.2.1":"http://cdn.intermine.org/js/intermine/widgets/1.2.1/intermine.widgets.js","1.3.0":"http://cdn.intermine.org/js/intermine/widgets/1.3.0/intermine.widgets.js","1.4.0":"http://cdn.intermine.org/js/intermine/widgets/1.4.0/intermine.widgets.js","1.4.1":"http://cdn.intermine.org/js/intermine/widgets/1.4.1/intermine.widgets.js","1.4.2":"http://cdn.intermine.org/js/intermine/widgets/1.4.2/intermine.widgets.js","1.6.7":"http://cdn.intermine.org/js/intermine/widgets/1.6.7/intermine.widgets.js","1.6.8":"http://cdn.intermine.org/js/intermine/widgets/1.6.8/intermine.widgets.js","1.7.0":"http://cdn.intermine.org/js/intermine/widgets/1.7.0/intermine.widgets.js","1.7.3":"http://cdn.intermine.org/js/intermine/widgets/1.7.3/intermine.widgets.js","1.8.0":"http://cdn.intermine.org/js/intermine/widgets/1.8.0/intermine.widgets.js","1.8.1":"http://cdn.intermine.org/js/intermine/widgets/1.8.1/intermine.widgets.js","1.8.2":"http://cdn.intermine.org/js/intermine/widgets/1.8.2/intermine.widgets.js","1.8.3":"http://cdn.intermine.org/js/intermine/widgets/1.8.3/intermine.widgets.js","1.9.1":"http://cdn.intermine.org/js/intermine/widgets/1.9.1/intermine.widgets.js","1.10.0":"http://cdn.intermine.org/js/intermine/widgets/1.10.0/intermine.widgets.js","1.11.2":"http://cdn.intermine.org/js/intermine/widgets/1.11.2/intermine.widgets.js"},"report-widgets":{"latest":"http://cdn.intermine.org/js/intermine/report-widgets/latest/intermine.report-widgets.js","0.7.0":"http://cdn.intermine.org/js/intermine/report-widgets/0.7.0/intermine.report-widgets.js"}};
}).call(this);