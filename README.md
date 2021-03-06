#InterMine API Loader

Simplify loading of JS and CSS dependencies.

[ ![Codeship Status for intermine/intermine-api-loader](https://www.codeship.io/projects/3543c3f0-9498-0130-d02b-2af0f23c7f6c/status?branch=master)](https://www.codeship.io/projects/3085)

## Quickstart

Include `intermine.api.js` on a page then resolve dependencies as follows:

```javascript
intermine.load({
  'js': {
    'JSON': {
      'path': 'http://cdn.intermine.org/js/json3/3.2.2/json3.min.js'
    },
    'setImmediate': {
      'path': 'http://cdn.intermine.org/js/setImmediate/1.0.1/setImmediate.min.js'
    },
    'example': {
      'path': 'http://',
      'test': function() {
        return true;
      }
    },
    'async': {
      'path': 'http://cdn.intermine.org/js/async/0.2.6/async.min.js',
      'depends': ['setImmediate']
    },
    'jQuery': {
      'path': 'http://cdn.intermine.org/js/jquery/1.8.2/jquery.min.js',
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
```

## Build your Own

```bash
$ npm install
$ make build
```

## Test in CLI

```bash
$ npm install
$ make test
```

## Spec

1. Each dependency to load is grouped under either a `css` or `js` key.
2. A dependency is loaded only if it does not exist on the page already. There are two ways to determine that:
  1. Check the name key of the library as to whether or not it is exposed on the `window` object.
  1. If a `test` function is provided, run it and continue only if we get `false` back.
3. URL to the dependency is defined under the `path` key.
4. A dependency will be resolved only after all dependencies are met which is defined in an Array under `depends` key.
5. If two requests to load dependency X come at the same time we make only one load and use cache for the second.
6. CSS is a bit random so we just load whatever you ask for not waiting for anything.
7. Keys `load` and `loader` are taken over by us on the `intermine` namespace.
8. **The last parameter of `load` is a callback. Use it, it might respond with an error.**