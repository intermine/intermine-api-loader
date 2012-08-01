InterMine JavaScript API Loader

## Why?
1. To simplify delivery of InterMine's JavaScript clients.
2. JS API provides a common namespace `intermine` for all our JavaScript.
3. Can/will be utilized as a loader of dependencies such as jQuery, underscore etc. whenever needed.
4. As JavaScript is namespaced, we can determine which of our libraries are already loaded.

## Use

### List Widgets

#### In a mine context

Point to the loader in a CDN.

```html
<script src="http://cdn.intermine.org/api"></script>
```

Specify that you want to load list widgets for a specific service.

```javascript
intermine.load('list-widgets', 'http://flymine.org', function(widgets) {
  // ...
});
```

#### In an embedding context

Point to the api and list widgets loader locally.

```html
// point to API, requirement for all InterMine client side JavaScript
<script src="js/intermine.api.js"></script>
// include List Widgets library locally, is immediately available on the `intermine` namespace
<script src="js/intermine.list-widgets.js"></script>
```

Now make a connection to a service.

```javascript
var widgets = new intermine.widgets('http://flymine.org');
```