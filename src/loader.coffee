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

# Overridable config.
intermine.loader =
    # Quit with error callback if we do not get a file in this much time (in ms).
    'timeout': 1e4
    # When waiting for a library to get processed, this is the cutoff time (in ms).
    'processing': 50
    # The function launching the (one) file loading.
    'fn': (path, type='js', cb) ->
        switch type
            when 'js' then _get.script path, cb
            when 'css' then _get.style path, cb
            else cb "Unrecognized type `#{type}`"

# Dependencies that are being loaded are put here.
loading = {}

# Jobs executed.
jobs = 0

# A new auto-loader.
load = (resources, type, cb) ->
    job = ++jobs

    log  { 'job': job, 'message': 'start' }

    # Is a resource on a `window`?
    onWindow = (path) ->
        # Skip JSONP requests.
        return false if ~path.indexOf '?'

        # Where do we start?
        loc = root.window
        # Split on a dot.
        for part in path.split('.')
            # Exit if not found.
            return false unless (loc[part]? and (typeof loc[part] is 'function' or 'object'))
            # OK, traverse deeper then.
            loc = loc[part]

        # It must exist on `window`.
        true

    # Have we exited already?
    exited = false
    exit = (err) ->
        exited = true
        cb err
    
    # Create the object for async.
    obj = {}

    # Check & format the resources.
    for key, value of resources then do (key, value) ->
        log { 'job': job, 'library': key, 'message': 'start' }

        # Skip if an error has happened.
        return if exited

        # Expand in our scope.
        { path, test, depends } = value

        # Check we have the URL path.
        return exit "Library `path` not provided for #{key}" unless path

        # Do we have a sync function check?
        if !!(test and typeof(test) is 'function' and test()) or
            # Let us attempt a check on the `window` then.
            onWindow(key)
                log { 'job': job, 'library': key, 'message': 'exists' }
                # Add an immediate callback to the object :).
                return obj[key] = (cb) -> cb null

        # Maybe this library is being loaded right now elsewhere on the page?
        if loading[key]
            log { 'job': job, 'library': key, 'message': 'will wait' }
            # OK, register ourselves to be told when ready.
            return obj[key] = (cb) ->
                loading[key].push cb

        # Create an Array for callbacks if someone is interested in us.
        loading[key] = []

        # Straight up fetch.
        log { 'job': job, 'library': key, 'message': 'will download' }
        obj[key] = (cb) ->
            log { 'job': job, 'library': key, 'message': 'downloading' }
            
            # Give the loader this amount of time to download the lib.
            timeout = root.window.setTimeout ->
                log { 'job': job, 'library': key, 'message': 'timed out' }
                postCall "The library `#{key}` has timed out"
            , intermine.loader.timeout

            postCall = (err) ->
                return if exited
                # Clear the timeout.
                clearTimeout timeout

                if err
                    delete loading[key] # no callbacks for you!
                    return exit err

                # OK all good.
                log { 'job': job, 'library': key, 'message': 'downloaded' }

                # Call this when the library is ready to use.
                isReady = ->
                    log { 'job': job, 'library': key, 'message': 'ready' }

                    # Execute all of out callbacks if any.
                    while loading[key].length isnt 0
                        do loading[key].pop()

                    # OK, no more calling others..
                    delete loading[key]

                    cb null

                # Now we need to allow for processing time.
                timeout = root.window.setTimeout isReady, intermine.loader.processing

                # Keep checking the `window` for when the lib shows up.
                do isAvailable = ->
                    # Do we have a sync function check?
                    if !!(test and typeof(test) is 'function' and test()) or
                        # Let us attempt a check on the `window` then.
                        onWindow(key)
                            log { 'job': job, 'library': key, 'message': 'exists' }
                            # Remove the cutoff timeout.
                            root.window.clearTimeout timeout
                            # We say it is ready.
                            isReady()

                    # Keep checking then.
                    else
                        _setImmediate isAvailable

            # Launch the loader.
            intermine.loader.fn path, type, postCall

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
            if !!wait and !!parseInt(i) # stupid to wait when we are first
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

# Logger.
intermine.log = [] unless (intermine.log and intermine.log instanceof Array)
log = -> intermine.log.push [ 'api-loader', (new Date).toLocaleString(), (JSON.stringify(arg) for arg in arguments).join(' ') ]