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
        
        taskCallback = (err) ->
            args = Array::slice.call(arguments, 1)
            args = args[0] if args.length <= 1
            if err
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
            task[task.length - 1] taskCallback, results
        else
            listener = ->
                if ready()
                    removeListener listener
                    task[task.length - 1] taskCallback, results

            addListener listener