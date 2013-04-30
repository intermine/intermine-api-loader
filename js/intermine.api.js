(function() {
  var CSSLoader, JSLoader, async, load, root, _each, _keys, _reduce;
  
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
    var key, obj, value, _fn;
  
    obj = {};
    _fn = function(key, value) {
      var check, dep, depends, path;
  
      path = value.path, check = value.check, depends = value.depends;
      if (!path) {
        throw "Library `path` not provided for " + key;
      }
      if ((check && typeof check === 'function' && check()) || ((root[key] != null) && (typeof root[key] === 'function' || 'object'))) {
        return obj[key] = function(cb) {
          return cb();
        };
      }
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
        return obj[key] = depends.concat(function(cb) {
          return JSLoader(path, function() {
            return cb();
          });
        });
      }
      switch (type) {
        case 'js':
          return obj[key] = function(cb) {
            return JSLoader(path, function() {
              return cb();
            });
          };
        case 'css':
          return obj[key] = function(cb) {
            CSSLoader(path);
            return cb();
          };
        default:
          throw "Unrecognized type `" + type + "`";
      }
    };
    for (key in resources) {
      value = resources[key];
      _fn(key, value);
    }
    return async.auto(obj, cb);
  };
  
  root.intermine = root.intermine || {};
  
  if (intermine.load) {
    return;
  }
  
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
        library[i].name = name;
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
  
  async = {};
  
  _each = function(arr, iterator) {
    var key, value, _results;
  
    if (arr.forEach) {
      return arr.forEach(iterator);
    }
    _results = [];
    for (key in arr) {
      value = arr[key];
      _results.push(iterator(value, key, arr));
    }
    return _results;
  };
  
  _reduce = function(arr, iterator, memo) {
    if (arr.reduce) {
      return arr.reduce(iterator, memo);
    }
    _each(arr, function(x, i, a) {
      return memo = iterator(memo, x, i, a);
    });
    return memo;
  };
  
  _keys = function(obj) {
    var k, keys;
  
    if (Object.keys) {
      return Object.keys(obj);
    }
    keys = [];
    for (k in obj) {
      if (obj.hasOwnProperty(k)) {
        keys.push(k);
      }
    }
    return keys;
  };
  
  if (typeof setImmediate === 'function') {
    async.setImmediate = setImmediate;
  } else {
    async.setImmediate = function(fn) {
      return setTimeout(fn, 0);
    };
  }
  
  async.auto = function(tasks, callback) {
    var addListener, keys, listeners, removeListener, results, taskComplete;
  
    callback = callback || function() {};
    keys = _keys(tasks);
    if (!keys.length) {
      return callback(null);
    }
    results = {};
    listeners = [];
    addListener = function(fn) {
      return listeners.unshift(fn);
    };
    removeListener = function(fn) {
      var i, listener;
  
      for (i in listeners) {
        listener = listeners[i];
        if (listener === fn) {
          listeners.splice(i, 1);
          return;
        }
      }
    };
    taskComplete = function() {
      return _each(listeners.slice(0), function(fn) {
        return fn();
      });
    };
    addListener(function() {
      if (_keys(results).length === keys.length) {
        callback(null, results);
        return callback = function() {};
      }
    });
    return _each(keys, function(k) {
      var listener, ready, requires, task, taskCallback;
  
      task = (tasks[k] instanceof Function ? [tasks[k]] : tasks[k]);
      taskCallback = function(err) {
        var args, safeResults;
  
        args = Array.prototype.slice.call(arguments, 1);
        if (args.length <= 1) {
          args = args[0];
        }
        if (err) {
          safeResults = {};
          _each(_keys(results), function(rkey) {
            return safeResults[rkey] = results[rkey];
          });
          safeResults[k] = args;
          callback(err, safeResults);
          return callback = function() {};
        } else {
          results[k] = args;
          return async.setImmediate(taskComplete);
        }
      };
      requires = task.slice(0, Math.abs(task.length - 1)) || [];
      ready = function() {
        return _reduce(requires, function(a, x) {
          return a && results.hasOwnProperty(x);
        }, true) && !results.hasOwnProperty(k);
      };
      if (ready()) {
        return task[task.length - 1](taskCallback, results);
      } else {
        listener = function() {
          if (ready()) {
            removeListener(listener);
            return task[task.length - 1](taskCallback, results);
          }
        };
        return addListener(listener);
      }
    });
  };
  
intermine.resources = {"widgets":{"latest":"http://cdn.intermine.org/js/intermine/widgets/latest/intermine.widgets.js","1.0.0":"http://cdn.intermine.org/js/intermine/widgets/1.0.0/intermine.widgets.js","1.1.0":"http://cdn.intermine.org/js/intermine/widgets/1.1.0/intermine.widgets.js","1.1.7":"http://cdn.intermine.org/js/intermine/widgets/1.1.7/intermine.widgets.js","1.1.8":"http://cdn.intermine.org/js/intermine/widgets/1.1.8/intermine.widgets.js","1.1.9":"http://cdn.intermine.org/js/intermine/widgets/1.1.9/intermine.widgets.js","1.1.10":"http://cdn.intermine.org/js/intermine/widgets/1.1.10/intermine.widgets.js","1.2.0":"http://cdn.intermine.org/js/intermine/widgets/1.2.0/intermine.widgets.js","1.2.1":"http://cdn.intermine.org/js/intermine/widgets/1.2.1/intermine.widgets.js","1.3.0":"http://cdn.intermine.org/js/intermine/widgets/1.3.0/intermine.widgets.js","1.4.0":"http://cdn.intermine.org/js/intermine/widgets/1.4.0/intermine.widgets.js","1.4.1":"http://cdn.intermine.org/js/intermine/widgets/1.4.1/intermine.widgets.js","1.4.2":"http://cdn.intermine.org/js/intermine/widgets/1.4.2/intermine.widgets.js","1.6.7":"http://cdn.intermine.org/js/intermine/widgets/1.6.7/intermine.widgets.js","1.6.8":"http://cdn.intermine.org/js/intermine/widgets/1.6.8/intermine.widgets.js","1.7.0":"http://cdn.intermine.org/js/intermine/widgets/1.7.0/intermine.widgets.js","1.7.3":"http://cdn.intermine.org/js/intermine/widgets/1.7.3/intermine.widgets.js","1.8.0":"http://cdn.intermine.org/js/intermine/widgets/1.8.0/intermine.widgets.js","1.8.1":"http://cdn.intermine.org/js/intermine/widgets/1.8.1/intermine.widgets.js","1.8.2":"http://cdn.intermine.org/js/intermine/widgets/1.8.2/intermine.widgets.js","1.8.3":"http://cdn.intermine.org/js/intermine/widgets/1.8.3/intermine.widgets.js","1.9.1":"http://cdn.intermine.org/js/intermine/widgets/1.9.1/intermine.widgets.js","1.10.0":"http://cdn.intermine.org/js/intermine/widgets/1.10.0/intermine.widgets.js","1.11.2":"http://cdn.intermine.org/js/intermine/widgets/1.11.2/intermine.widgets.js"},"report-widgets":{"latest":"http://cdn.intermine.org/js/intermine/report-widgets/latest/intermine.report-widgets.js","0.7.0":"http://cdn.intermine.org/js/intermine/report-widgets/0.7.0/intermine.report-widgets.js"}};
}).call(this);