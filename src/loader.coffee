#!/usr/bin/env coffee
root = this

# Export.
root.intermine = intermine = root.intermine or {}

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
                root.setTimeout cb, 0
    
    switch type
        when 'js'
            script = document.createElement 'script'
            script.src = path
            script.type = 'text/javascript'
            setCallback(script, cb) if cb
            document.getElementsByTagName('head')[0].appendChild(script)

        when 'css'
            sheet = document.createElement 'link'
            sheet.rel = 'stylesheet'
            sheet.type = 'text/css'
            sheet.href = path
            document.getElementsByTagName('head')[0].appendChild(sheet)
            # Immediate callback, do not wait for anything.
            cb()

        else
            throw "Unrecognized type `#{type}`"

# Dependencies that are being loaded are put here.
loading = {}

# A new auto-loader.
load = (resources, type, cb) ->
    # Create the object for async.
    obj = {}
    for key, value of resources then do (key, value) ->
        # Expand in our scope.
        { path, check, depends } = value

        # Check we have the URL path.
        throw "Library `path` not provided for #{key}" unless path

        # Do we have a sync function check?
        if (check and typeof check is 'function' and check()) or
            # Let us attempt a check on the window then.
            (root[key]? and (typeof root[key] is 'function' or 'object'))
                # Add an immediate callback to the object :).
                return obj[key] = (cb) -> cb()

        # Maybe this library is being loaded right now elsewhere on the page?
        if loading[key]
            # OK, be called when it is done.
            return obj[key] = (cb) ->
                # Wait for the library to be loaded.
                do isDone = ->
                    unless loading[key]
                        setTimeout isDone, 0
                    else
                        cb() # finally the dependency got loaded

        # This dep is registered for loading.
        loading[key] = true

        # Straight up fetch.
        obj[key] = (cb) ->
            intermine.loader path, type, ->
                delete loading[key] # has loaded...
                cb()

        # Do we have dependencies?
        if depends and depends instanceof Array
            # Make sure we recognize them.
            ( throw "Unrecognized dependency `#{dep}`" unless resources[dep]? for dep in depends )
            # Append our loader after the deps.
            return obj[key] = depends.concat obj[key]

    # Pass to async to work it all out.
    async.auto obj, (err, results) ->
        throw err if err
        cb()

# Public interface that converts various types of input into the standard.
intermine.load = (library, version, cb) ->
    # Has a version been passed in?
    if typeof version is 'function'
        cb = version
        version = 'latest'

    # If library is a string and we have version defined, we are a "named" resource.
    if typeof library is 'string'
        # Do we know this library?
        throw "Unknown library `#{library}`" unless paths[library]
        throw "Unknown `#{library}` version #{version}" unless (path = paths[library][version])

        o = {}
        o["intermine.#{library}"] = 'path': path

        return load o, 'js', cb

    # If we are an Array, convert to the new way of loading.
    # This method is deprecated in favor of providing an object.
    if library instanceof Array
        o = 'js': {}, 'css': {}

        # Explode the config.
        for i, { name, path, type, wait } of library
            throw 'Library `path` or `type` not provided' unless path or type
            throw "Library type `#{type}` not recognized" if type not in [ 'css', 'js' ]
            
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
        
        # Call back when all is done padre.
        handle = -> return cb() if ( i-- and not !!i )

        # Launch them all.
        return ( load resources, key, handle for key, resources of library )

    throw 'Unrecognized input'