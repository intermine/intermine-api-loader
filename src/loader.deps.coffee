#!/usr/bin/env coffee

# `setImmediate` for node and the browser.
if typeof process is 'undefined' or not (process.nextTick)
    if typeof setImmediate is 'function'
        _setImmediate = setImmediate
    else
        _setImmediate = (fn) -> setTimeout fn, 0
else
    if typeof setImmediate isnt 'undefined'
        _setImmediate = setImmediate
    else
        _setImmediate = process.nextTick

# Microsoft sucks... 
_each = (arr, iterator) ->
    return arr.forEach(iterator) if arr.forEach
    ( iterator(value, key, arr) for key, value of arr )

_map = (arr, iterator) ->
    return arr.map(iterator) if arr.map
    results = []
    _each arr, (x, i, a) ->
        results.push iterator(x, i, a)
    results

_reduce = (arr, iterator, memo) ->
    return arr.reduce(iterator, memo) if arr.reduce
    _each arr, (x, i, a) ->
        memo = iterator(memo, x, i, a)
    memo

_keys = (obj) ->
    return Object.keys(obj) if Object.keys
    keys = []
    for k of obj
        keys.push k if obj.hasOwnProperty(k)
    keys

_contains = (arr, item) ->
    return arr.indexOf(item) >= 0 if [].indexOf
    ( return true for value in arr when value is item )
    false

# A mini `async.auto` implementation.
_auto = (tasks, callback) ->
    callback = callback or ->
    keys = _keys tasks
    return callback(null) unless keys.length
    
    results = {}    
    listeners = []
    
    addListener = (fn) -> listeners.unshift fn
    
    removeListener = (fn) ->
        for i, listener of listeners
            if listener is fn
                listeners.splice i, 1
                return

    taskComplete = ->
        _each listeners.slice(0), (fn) ->
            fn()

    addListener ->
        if _keys(results).length is keys.length
            callback null, results
            callback = ->

    _each keys, (k) ->
        task = (if (tasks[k] instanceof Function) then [tasks[k]] else tasks[k])
        
        # Call this when task has finished.
        taskCallback = (err) ->
            args = Array::slice.call(arguments, 1)
            args = args[0] if args.length <= 1
            if err # trouble in paradise?
                safeResults = {}
                _each _keys(results), (rkey) ->
                    safeResults[rkey] = results[rkey]

                safeResults[k] = args
                callback err, safeResults
                
                # stop subsequent errors hitting callback multiple times
                callback = ->
            else
                results[k] = args
                _setImmediate taskComplete

        requires = task.slice(0, Math.abs(task.length - 1)) or []

        ready = ->
            _reduce(requires, (a, x) ->
                a and results.hasOwnProperty(x)
            , true) and not results.hasOwnProperty(k)

        if ready()
            # Call the next task.
            task[task.length - 1] taskCallback, results
        else
            listener = ->
                if ready()
                    removeListener listener
                    task[task.length - 1] taskCallback, results

            addListener listener

# Document & head refs.
document = root.window.document
head = document.head or document.getElementsByTagName('head')[0] if document

# Resource loader.
_get =
    # Fetch a JavaScript file.
    'script': (url, cb) ->
        return cb '`window.document` does not exist' unless head

        done = ->
            # Clean up circular references to prevent memory leaks in IE
            script.onload = script.onreadystatechange = script.onerror = null
          
            # Remove script element once loaded
            head.removeChild script
            cb and cb.call root.window, (if loaded then null else '`script.onerror` fired')

        script = document.createElement 'script'
        loaded = false

        # Default type.
        script.type = 'text/javascript'
        # Some libs like d3 need this.
        script.charset = 'utf-8'
        # Extra hint for good browsers.
        script.async = true
        # The URL path.
        script.src = url

        # Handle events...
        script.onload = script.onreadystatechange = (event) ->
            event = event or root.window.event

            if event.type is 'load' or (/loaded|complete/.test(script.readyState) and (not document.documentMode or document.documentMode < 9))
                # All good.
                loaded = true
                # Release event listeners.
                script.onload = script.onreadystatechange = script.onerror = null
                # Do callback.
                _setImmediate done

        script.onerror = (event) ->
            event = event or root.window.event
            # Release event listeners.
            script.onload = script.onreadystatechange = script.onerror = null
            # Do callback.
            _setImmediate done

        # Launch.
        head.insertBefore script, head.lastChild

    # Fetch a CSS stylesheet.
    'style': (url, cb) ->
        style = document.createElement 'link'

        style.rel = 'stylesheet'
        style.type = 'text/css'
        style.href = url

        # Launch.
        head.insertBefore style, head.lastChild

        # Immediate yet async callback.
        _setImmediate cb