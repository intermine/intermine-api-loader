InterMine JavaScript API Loader

## Why?
1. To simplify delivery of InterMine's JavaScript clients.
2. JS API provides a common namespace `intermine` for all our JavaScript.
3. Can/will be utilized as a loader of dependencies such as jQuery, underscore etc. whenever needed.
4. As JavaScript is namespaced, we can determine which of our libraries are already loaded.

## Requirements

![image](https://github.com/radekstepan/intermine-api-loader/raw/report-widgets/widgets.png)

### CDN Role

A repository of different versions of widgets and libraries InterMine depends on.

### Mine Roles

1. Inject `callback` identifier into widget loaders coming from CDN so we can have multiple versions of these on one page.
2. For **List Widgets** to read XML config and execute appropriate JAVA classes to process results into JS for the widget loader.
3. For **Report Widgets** to mash widget resources like templates, presenter, CSS and config together and serve under a callback in JS format.

### API Loader Roles

1. Serve as a cache of different widget loaders (report & list) for the different mines we point to on a page.
2. For dependencies (JS, CSS) determine if we actually need to load them or not from a CDN.

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