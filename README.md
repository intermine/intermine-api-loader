InterMine JavaScript API Loader

## Why?
1. To simplify delivery of InterMine's JavaScript clients.
2. JS API provides a common namespace `intermine` for all our JavaScript.
3. Can/will be utilized as a loader of dependencies such as jQuery, underscore etc. whenever needed.
4. As JavaScript is namespaced, we can determine which of our libraries are already loaded.

## Use:

<table>
    <thead>
        <tr>
            <th></th>
            <th>List Widgets</th>
            <th>Report Widgets</th>
        </tr>
    </thead>
    <tbody>
        <tr>
            <th>Mine context</th>
            <td>
```html
<script src="http://cdn.intermine.org/api"></script>
```

```javascript
intermine.load('widgets', function() {
  var widgets = new intermine.widgets('http://flymine.org/service');
});
```
            </td>
        </tr>
        <tr>
            <th>Embed context</th>
            <td>
```html
// include jQuery locally
<script src="js/jquery.js"></script>

// point to API, requirement for all InterMine client side JavaScript
<script src="js/intermine.api.js"></script>
// include List Widgets library locally, is immediately available on the `intermine` namespace
<script src="js/intermine.list-widgets.js"></script>
```

```javascript
var widgets = new intermine.widgets('http://flymine.org/service');
```
            </td>
        </tr>
    </tbody>
</table>