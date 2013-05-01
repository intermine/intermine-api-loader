#!/usr/bin/env coffee
root = this

# Export.
root.intermine = intermine = root.intermine or {}

# Work in Node.
if typeof root.window is 'undefined'
    throw 'what kind of environment is this?' if typeof global is 'undefined'
    root.window = global

# Only allow one instance.
return if intermine.load

# Export the loader so we can override when testing.
intermine.loader = (path, type='js', cb) ->
    # Give us a call when you are done.
    setCallback = (tag, cb) ->
        tag.onload = cb
        tag.onreadystatechange = ->
            state = tag.readyState
            if state is 'complete' or state is 'loaded'
                tag.onreadystatechange = null
                _setImmediate cb
    
    switch type
        when 'js'
            script = document.createElement 'script'
            script.src = path
            script.type = 'text/javascript'
            setCallback(script, cb)
            document.getElementsByTagName('head')[0].appendChild(script)

        when 'css'
            sheet = document.createElement 'link'
            sheet.rel = 'stylesheet'
            sheet.type = 'text/css'
            sheet.href = path
            document.getElementsByTagName('head')[0].appendChild(sheet)
            # Immediate callback, do not wait for anything.
            cb null

        else
            cb "Unrecognized type `#{type}`"

# Dependencies that are being loaded are put here.
loading = {}

# A new auto-loader.
load = (resources, type, cb) ->
    # Have we exited already?
    exited = false
    exit = (err) ->
        exited = true
        cb err
    
    # Create the object for async.
    obj = {}

    # Check & format the resources.
    for key, value of resources then do (key, value) ->
        # Skip if an error has happened.
        return if exited

        # Expand in our scope.
        { path, check, depends } = value

        # Check we have the URL path.
        return exit "Library `path` not provided for #{key}" unless path

        # Do we have a sync function check?
        if !!(check and typeof(check) is 'function' and check()) or
            # Let us attempt a check on the `window` then.
            (root.window[key]? and (typeof root.window[key] is 'function' or 'object'))
                # Add an immediate callback to the object :).
                return obj[key] = (cb) -> cb null

        # Maybe this library is being loaded right now elsewhere on the page?
        if loading[key]
            # OK, be called when it is done.
            return obj[key] = (cb) ->
                # Wait for the library to be loaded.
                do isDone = ->
                    unless loading[key]
                        _setImmediate isDone # works in node & browser
                    else
                        cb null # finally the dependency got loaded

        # This dep is registered for loading.
        loading[key] = true

        # Straight up fetch.
        obj[key] = (cb) ->
            intermine.loader path, type, ->
                delete loading[key] # has loaded...
                cb null

        # Do we have dependencies?
        if depends and depends instanceof Array
            # Make sure we recognize them.
            for dep in depends when typeof(dep) isnt 'string' or not resources[dep]?
                delete loading[key] # no more soup for you!
                return exit "Unrecognized dependency `#{dep}`"
            
            # Append our loader after the deps.
            return obj[key] = depends.concat obj[key]

    # We have not exited yet right?
    return if exited

    # Check for cicular dependencies.
    err = []

    # Only get entries that depend on each other.
    for key, value of obj when value instanceof Array
        seen = {} # keep track of entries we have seen
        
        # Resolve the dependency tree up until its leaf nodes.
        ( branch = (key) ->
            return if typeof key isnt 'string' # duplo check

            if seen[key]? # have we seen you?
                err.push key unless _contains err, key # do not duplicate
            else
                seen[key] = yes # now we have seen you
                if (val = obj[key]) instanceof Array # do we have dependencies?
                    for i in [0...val.length - 1] # last one is a callback fn
                        branch val[i] # check this dependency then
        ) key

    if !!err.length
        # Remove all keys from loading list.
        delete loading[key] for key in _keys(obj)
        return exit "Circular dependencies detected for `#{err}`"

    # Pass to async to work it all out.
    _auto obj, (err) -> if err then cb err else cb null

# Public interface that converts various types of input into the standard.
intermine.load = (library, args...) ->
    # Callback always goes last.
    cb = if arguments.length is 1 then library else args.pop()
    # By default we have latest version for string libraries.
    version = 'latest'

    # Has a version been passed in?
    if typeof args[0] is 'string' then version = args[0]

    # Old loaders might not have a callback defined, go plain.
    if typeof cb isnt 'function' then cb = ->

    # If library is a string and we have version defined, we are a "named" resource.
    if typeof library is 'string'
        # Do we know this library?
        return cb "Unknown library `#{library}`" unless paths[library]
        return cb "Unknown `#{library}` version #{version}" unless (path = paths[library][version])

        o = {}
        o["intermine.#{library}"] = 'path': path

        return load o, 'js', cb

    # If we are an Array, convert to the new way of loading.
    # This method is deprecated in favor of providing an object.
    if library instanceof Array
        o = 'js': {}, 'css': {}

        # Explode the config.
        for i, { name, path, type, wait } of library
            return cb 'Library `path` or `type` not provided' unless path or type
            return cb "Library type `#{type}` not recognized" if type not in [ 'css', 'js' ]
            
            # Name is strictly not provided, so make one up from path if needed.
            name = path.split('/').pop() unless name

            # Save this on us so we can use it after us.
            library[i].name = name

            # Save this one.
            o[type][name] = 'path': path

            # Are we waiting for the previous one? Make it a dep.
            if !!wait and i isnt 0 # stupid to wait when we are first
                o[type][name].depends = [ library[i - 1].name ] # we have checked the name of our predecessor already

        # Library is an object now.
        library = o

    # Load resources specified as an object (new way).
    if typeof library is 'object'
        # We are going to be loading this many...
        i = _keys(library).length
        
        # Have we exited already?
        exited = false

        # Call back when all is done padre.
        handle = (err) ->
            return if exited # late to the party?
            if err # you broken boy
                exited = true
                return cb err
            
            return cb null if ( i-- and not !!i ) # are we there yet?

        # Launch them all.
        return ( load resources, key, handle for key, resources of library )

    cb 'Unrecognized input'