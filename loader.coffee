# Asynchronously load resources by adding them to the `<head>` and use callback.
class Loader

    getHead: -> document.getElementsByTagName('head')[0]

    setCallback: (tag, callback) ->
        tag.onload = callback
        tag.onreadystatechange = ->
            state = tag.readyState
            if state is "complete" or state is "loaded"
                tag.onreadystatechange = null
                window.setTimeout callback, 0


class JSLoader extends Loader

    constructor: (path, callback) ->
        script = document.createElement "script"
        script.src = path
        script.type = "text/javascript"
        @setCallback(script, callback) if callback
        @getHead().appendChild(script)


class CSSLoader extends Loader

    constructor: (path, callback) ->
        sheet = document.createElement "link"
        sheet.rel = "stylesheet"
        sheet.type = "text/css"
        sheet.href = path
        # CSS callbacks are messy; http://www.phpied.com/when-is-a-stylesheet-really-loaded/
        @setCallback(sheet, callback) if callback
        @getHead().appendChild(sheet)


# Pass resources to Load and it will call you back once everything is done.
class Load

    wait: false

    constructor: (resources, @callback) ->
        # We need to sort out this much.
        @count = resources.length
        
        # Initial load.
        @load resources.reverse()

    load: (resources) =>   
        # Do we need to wait before continuing?
        if @wait then window.setTimeout((=> @load resources), 0)
        else
            # Is that all?
            if resources.length
                # Remove the 'first' resource from the queue.
                resource = resources.pop()

                # Wait?
                @wait = true if resource.wait?

                # What type is it?            
                switch resource.type
                    when "js"
                        # Do we need to actually download it? Check for resource name.
                        if resource.name?
                            # Bastardly browsers (IE, Webkit, Opera) attach `<div>` elements by their id to `window`.
                            if window[resource.name]? and (typeof window[resource.name] is "function" or "object") then @done resource
                            else new JSLoader(resource.path, => @done resource)
                        # Standard load.
                        else new JSLoader(resource.path, => @done resource)
                    when "css"
                        # Just load it.
                        new CSSLoader resource.path ; @done resource

            # Call back when all is done.
            if @count or @wait then window.setTimeout((=> @load resources), 0) else @callback()

    done: (resource) =>
        @wait = false if resource.wait? # Wait no more.
        @count -= 1 # One less.


# --------------------------------------------


if not window['InterMine'] then window['InterMine'] = {}

InterMine.namespace = (namespace, obj) ->
    parent = window['InterMine']
    for part in namespace.split '.'
        parent[part] = parent[part] or {}
        parent = parent[part]
    parent

InterMine.load = (opts...) ->
    library = opts[0]
    (typeof opts[1] is 'function' and version = 'latest') or version = opts[1]
    callback = opts.pop()

    if InterMine.resources[library]?
        if InterMine.resources[library][version]?
            new Load InterMine.resources[library][version], callback
        else
            console.log "#{library} #{version} is not supported at the moment"
    else
        console.log "#{library} is not supported at the moment"


# --------------------------------------------


InterMine.resources =
    'Widgets':
        'latest': [
            name:  "jQuery"
            path:  "http://cdnjs.cloudflare.com/ajax/libs/jquery/1.7.2/jquery.min.js"
            type:  "js"
            wait:  true
        ,
            name:  "_"
            path:  "http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.3.3/underscore-min.js"
            type:  "js"
            wait:  true
        ,
            name:  "Backbone"
            path:  "http://cdnjs.cloudflare.com/ajax/libs/backbone.js/0.9.2/backbone-min.js"
            type:  "js"
            wait:  true
        ,
            name:  "google"
            path:  "https://www.google.com/jsapi"
            type:  "js"
        ,
            path:  "https://raw.github.com/alexkalderimis/imjs/master/src/model.js"
            type:  "js"
        ,
            path:  "https://raw.github.com/alexkalderimis/imjs/master/src/query.js"
            type:  "js"
        ,
            path:  "https://raw.github.com/alexkalderimis/imjs/master/src/service.js"
            type:  "js"
        ,
            path:  "https://raw.github.com/radekstepan/intermine-widget-client/master/js/widgets.js"
            type:  "js"
        ]
        'd3': [
            name:  "jQuery"
            path:  "http://cdnjs.cloudflare.com/ajax/libs/jquery/1.7.2/jquery.min.js"
            type:  "js"
            wait:  true
        ,
            name:  "_"
            path:  "http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.3.3/underscore-min.js"
            type:  "js"
            wait:  true
        ,
            name:  "Backbone"
            path:  "http://cdnjs.cloudflare.com/ajax/libs/backbone.js/0.9.2/backbone-min.js"
            type:  "js"
            wait:  true
        ,
            name:  "d3"
            path:  "https://raw.github.com/shutterstock/rickshaw/master/vendor/d3.min.js"
            type:  "js"
        ]
    'imjs':
        'latest': [
            name:  "_"
            path:  "http://cdnjs.cloudflare.com/ajax/libs/underscore.js/1.3.3/underscore-min.js"
            type:  "js"
            wait:  true
        ,
            path:  "https://raw.github.com/alexkalderimis/imjs/master/src/model.js"
            type:  "js"
        ,
            path:  "https://raw.github.com/alexkalderimis/imjs/master/src/query.js"
            type:  "js"
        ,
            path:  "https://raw.github.com/alexkalderimis/imjs/master/src/service.js"
            type:  "js"
        ]