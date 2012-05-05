(function() {
  var CSSLoader, JSLoader, Load, Loader,
    __hasProp = {}.hasOwnProperty,
    __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor; child.__super__ = parent.prototype; return child; },
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = [].slice;

  Loader = (function() {

    Loader.name = 'Loader';

    function Loader() {}

    Loader.prototype.getHead = function() {
      return document.getElementsByTagName('head')[0];
    };

    Loader.prototype.setCallback = function(tag, callback) {
      tag.onload = callback;
      return tag.onreadystatechange = function() {
        var state;
        state = tag.readyState;
        if (state === "complete" || state === "loaded") {
          tag.onreadystatechange = null;
          return window.setTimeout(callback, 0);
        }
      };
    };

    return Loader;

  })();

  JSLoader = (function(_super) {

    __extends(JSLoader, _super);

    JSLoader.name = 'JSLoader';

    function JSLoader(path, callback) {
      var script;
      script = document.createElement("script");
      script.src = path;
      script.type = "text/javascript";
      if (callback) {
        this.setCallback(script, callback);
      }
      this.getHead().appendChild(script);
    }

    return JSLoader;

  })(Loader);

  CSSLoader = (function(_super) {

    __extends(CSSLoader, _super);

    CSSLoader.name = 'CSSLoader';

    function CSSLoader(path, callback) {
      var sheet;
      sheet = document.createElement("link");
      sheet.rel = "stylesheet";
      sheet.type = "text/css";
      sheet.href = path;
      if (callback) {
        this.setCallback(sheet, callback);
      }
      this.getHead().appendChild(sheet);
    }

    return CSSLoader;

  })(Loader);

  Load = (function() {

    Load.name = 'Load';

    Load.prototype.wait = false;

    function Load(resources, callback) {
      this.callback = callback;
      this.done = __bind(this.done, this);

      this.load = __bind(this.load, this);

      this.count = resources.length;
      this.load(resources.reverse());
    }

    Load.prototype.load = function(resources) {
      var resource,
        _this = this;
      if (this.wait) {
        return window.setTimeout((function() {
          return _this.load(resources);
        }), 0);
      } else {
        if (resources.length) {
          resource = resources.pop();
          if (resource.wait != null) {
            this.wait = true;
          }
          switch (resource.type) {
            case "js":
              if (resource.name != null) {
                if ((window[resource.name] != null) && (typeof window[resource.name] === "function" || "object")) {
                  this.done(resource);
                } else {
                  new JSLoader(resource.path, function() {
                    return _this.done(resource);
                  });
                }
              } else {
                new JSLoader(resource.path, function() {
                  return _this.done(resource);
                });
              }
              break;
            case "css":
              new CSSLoader(resource.path);
              this.done(resource);
          }
        }
        if (this.count || this.wait) {
          return window.setTimeout((function() {
            return _this.load(resources);
          }), 0);
        } else {
          return this.callback();
        }
      }
    };

    Load.prototype.done = function(resource) {
      if (resource.wait != null) {
        this.wait = false;
      }
      return this.count -= 1;
    };

    return Load;

  })();

  if (!window['InterMine']) {
    window['InterMine'] = {};
  }

  InterMine.namespace = function(namespace, obj) {
    var parent, part, _i, _len, _ref;
    parent = window['InterMine'];
    _ref = namespace.split('.');
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      part = _ref[_i];
      parent[part] = parent[part] || {};
      parent = parent[part];
    }
    return parent;
  };

  InterMine.load = function() {
    var callback, library, opts, version;
    opts = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
    library = opts[0];
    (typeof opts[1] === 'function' && (version = 'latest')) || (version = opts[1]);
    callback = opts.pop();
    if (InterMine.resources[library] != null) {
      if (InterMine.resources[library][version] != null) {
        return new Load(InterMine.resources[library][version], callback);
      } else {
        return console.log("" + library + " " + version + " is not supported at the moment");
      }
    } else {
      return console.log("" + library + " is not supported at the moment");
    }
  };

  InterMine.resources = {
    'Widgets': {
      'latest': [
        {
          name: "jQuery",
          path: "http://cdnjs.cloudflare.com/ajax/libs/jquery/1.7.2/jquery.min.js",
          type: "js",
          wait: true
        }, {
          name: "_",
          path: "http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.3.3/underscore-min.js",
          type: "js",
          wait: true
        }, {
          name: "Backbone",
          path: "http://cdnjs.cloudflare.com/ajax/libs/backbone.js/0.9.2/backbone-min.js",
          type: "js",
          wait: true
        }, {
          name: "google",
          path: "https://www.google.com/jsapi",
          type: "js"
        }, {
          path: "https://raw.github.com/alexkalderimis/imjs/master/src/model.js",
          type: "js"
        }, {
          path: "https://raw.github.com/alexkalderimis/imjs/master/src/query.js",
          type: "js"
        }, {
          path: "https://raw.github.com/alexkalderimis/imjs/master/src/service.js",
          type: "js"
        }, {
          path: "https://raw.github.com/radekstepan/intermine-widget-client/master/js/widgets.js",
          type: "js"
        }
      ],
      'd3': [
        {
          name: "jQuery",
          path: "http://cdnjs.cloudflare.com/ajax/libs/jquery/1.7.2/jquery.min.js",
          type: "js",
          wait: true
        }, {
          name: "_",
          path: "http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.3.3/underscore-min.js",
          type: "js",
          wait: true
        }, {
          name: "Backbone",
          path: "http://cdnjs.cloudflare.com/ajax/libs/backbone.js/0.9.2/backbone-min.js",
          type: "js",
          wait: true
        }, {
          name: "d3",
          path: "https://raw.github.com/shutterstock/rickshaw/master/vendor/d3.min.js",
          type: "js"
        }
      ]
    },
    'imjs': {
      'latest': [
        {
          name: "_",
          path: "http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.3.3/underscore-min.js",
          type: "js",
          wait: true
        }, {
          path: "https://raw.github.com/alexkalderimis/imjs/master/src/model.js",
          type: "js"
        }, {
          path: "https://raw.github.com/alexkalderimis/imjs/master/src/query.js",
          type: "js"
        }, {
          path: "https://raw.github.com/alexkalderimis/imjs/master/src/service.js",
          type: "js"
        }
      ]
    }
  };

}).call(this);
