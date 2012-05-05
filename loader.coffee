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


if not window['intermine'] then window['intermine'] = {}

intermine.load = (opts...) ->
    library = opts[0]
    (typeof opts[1] is 'function' and version = 'latest') or version = opts[1]
    callback = opts.pop()

    # Internal loader.
    if library instanceof Array then return new Load library, callback

    # 'Public' loader.
    if intermine.resources[library]?
        if intermine.resources[library][version]?
            new Load [
                'name': "intermine.#{library}"
                'path': intermine.resources[library][version]
                'type': 'js'
            ], callback
        else
            console.log "#{library} #{version} is not supported at the moment"
    else
        console.log "#{library} is not supported at the moment"