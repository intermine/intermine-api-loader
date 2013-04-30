root = this

# Asynchronously load resources by adding them to the `<head>` and use callback.
class Loader

    getHead: -> document.getElementsByTagName('head')[0]

    setCallback: (tag, callback) ->
        tag.onload = callback
        tag.onreadystatechange = ->
            state = tag.readyState
            if state is 'complete' or state is 'loaded'
                tag.onreadystatechange = null
                root.setTimeout callback, 0


class JSLoader extends Loader

    constructor: (path, callback) ->
        script = document.createElement 'script'
        script.src = path
        script.type = 'text/javascript'
        @setCallback(script, callback) if callback
        @getHead().appendChild(script)


class CSSLoader extends Loader

    constructor: (path, callback) ->
        sheet = document.createElement 'link'
        sheet.rel = 'stylesheet'
        sheet.type = 'text/css'
        sheet.href = path
        # CSS callbacks are messy; http://www.phpied.com/when-is-a-stylesheet-really-loaded/
        @setCallback(sheet, callback) if callback
        @getHead().appendChild(sheet)

# A new auto-loader.
load = (resources, type, cb) ->
    # Create the object for async.
    obj = {}
    for key, { path, check, depends } of resources
        # Check we have the URL path.
        throw "Missing `path` for #{key}" unless path

        # Do we have a check?
        if check
            switch typeof check
                # A string check on window?
                when 'string'
                    if root[check]? and (typeof root[check] is 'function' or 'object')
                        console.log 'already have', key
                        continue
                # A sync function check.
                when 'function'
                    continue if check()
                else
                    throw "Misconfigured `check` for #{key}"

        # We will have to be loading.
        console.log 'load', key

    return

    async.auto
        'D': [ 'B', (cb) ->
            console.log 'D'
            setTimeout cb, 1
        ]
        'B': (cb) ->
            console.log 'B'
            setTimeout cb, 1
        'A': (cb) ->
            console.log 'A'
            setTimeout cb, 1
        'C': [ 'A', 'B', (cb) ->
            console.log 'C'
            setTimeout cb, 1
        ]

root.intermine = root.intermine or {}

intermine.load = (library, version, cb) ->
    # Has a version been passed in?
    if typeof version is 'function'
        cb = version
        version = 'latest'

    # If library is a string and we have version defined, we are a "named" resource.
    if typeof library is 'string'
        # Do we know this library?
        throw "Unknown library `#{library}`" unless intermine.resources[library]?
        throw "Unknown `#{library}` version #{version}" unless (path = intermine.resources[library][version])?

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

            # Save this one.
            o[type][name] = 'path': path, 'check': name

            # Are we waiting for the previous one? Make it a dep.
            if !!wait and i isnt 0 # stupid to wait when we are first
                o[type][name].depends = [ library[i - 1].name ] # we have checked the name of our predecessor already

        # Library is an object now.
        library = o

    # Load resources specified as an object (new way).
    if typeof library is 'object'
        # Go through the types we know about.
        for key in [ 'css', 'js' ]
            if (resources = library[key]) then load resources, key, cb
        return

    throw 'Unrecognized input'

# --------------------------------------------

intermine.load
    'css':
        'A':
            'path': 'http://a'
        'B':
            'path': 'http://b'
    'js':
        'A':
            'path': 'http://a'
            'depends': [ 'B' ]
        'B':
            'path': 'http://b'
            'check': -> true
        'C':
            'path': 'http://c'
            'depends': [ 'A', 'B' ]