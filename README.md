InterMine JavaScript API Loader

## Why?
1. To simplify delivery of InterMine's JavaScript clients.
2. JS API provides a common namespace `intermine` for all our JavaScript.
3. Can/will be utilized as a loader of dependencies such as jQuery, underscore etc. whenever needed.
4. As JavaScript is namespaced, we can determine which of our libraries are already loaded.

## Requirements

![image](https://github.com/radekstepan/intermine-api-loader/raw/report-widgets/widgets.png)

1. Serve as a cache of different widget loaders (report & list) for the different mines we point to on a page.
2. For dependencies (JS, CSS) determine if we actually need to load them or not.

## Use

Point to the loader in a CDN.

```html
<script src="http://cdn.intermine.org/api"></script>
```

### List Widgets

```javascript
intermine.load('list-widgets', 'http://flymine.org/service', function(widgets) {
    // now we can load individual list widgets
});
```

### Report Widgets

```javascript
intermine.load('report-widgets', 'http://flymine.org/service', function(widgets) {
    // now we can load individual report widgets
});
```