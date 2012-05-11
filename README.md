InterMine JavaScript API Loader

## Why?
1. To simplify delivery of InterMine's JavaScript clients.
2. JS Api provides a common namespace `intermine` for all our JavaScript.
3. Can/will be utilized as a loader of dependencies such as jQuery, underscore etc. whenever needed.
4. As JavaScript is namespaced, we can determine which of our libraries are already loaded.

## Use:

In an embedding context, the only dependency would be the jsapi, hosted remotely. We provide a callback and wait for the API to load the Widgets library.

```html
<script src="http://intermine.org/jsapi"></script>
```

```javascript
intermine.load('widgets', function() {
  var widgets = new intermine.widgets('http://flymine.org/service');
});
```

In a mine context we want to serve resources locally. As we include jquery locally this is recognized by jsapi and no internet connection is required.

```html
// include jQuery locally
<script src="js/jquery.js"></script>

// point to API, requirement for all InterMine client side JavaScript
<script src="js/intermine.api.js"></script>
// include Widgets library locally, is immediately available on the `intermine` namespace
<script src="js/intermine.widgets.js"></script>
```

```javascript
var widgets = new intermine.widgets('http://flymine.org/service');
```

Asking for a specific version of a library to be loaded.

```html
<script src="http://intermine.org/jsapi"></script>
```

```javascript
intermine.load('widgets', '0.9.1', function() {
  var widgets = new intermine.widgets('http://flymine.org/service');
});
```

Within a JavaScript library, load resources as asynchronously as possible.

```javascript
var resources = [
  {
    name: "jQuery",
    path: "http://cdnjs.cloudflare.com/ajax/libs/jquery/1.7.2/jquery.min.js",
    type: "js",
    wait: true
  }
];
intermine.load(resources, function() {
  // ...
});
    
```

## Example:

[FlyMine Beta Widgets](http://tinkerbin.com/wq6HkyoX) on Tinkerbin