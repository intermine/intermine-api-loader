fs      = require 'fs'
cs      = require 'coffee-script'
yaml    = require 'js-yaml'
async   = require 'async'
uglify  = require 'uglify-js'

# Load YAML file.
async.waterfall [ (cb) ->
    fs.readFile 'paths.yml', 'utf-8', (err, data) ->
        return cb err if err
        cb null, data

# YAML -> JSON.
(data, cb) ->
    try
        paths = JSON.stringify yaml.load data
        cb null, paths
    catch err
        return cb err

# Load the loader, dependencies & compile.
(paths, cb) ->
    compile = (f) ->
        (cb) ->
            fs.readFile f, 'utf-8', (err, data) ->
                return cb err if err
                cb null, [ f, data ]

    # Run checks in parallel.
    async.parallel ( compile f for f in [ './src/loader.coffee', './src/loader.deps.coffee' ] ), (err, results) ->
        return cb err if err

        # Swap?
        [ a, b ] = results
        ( a[0] is './src/loader.coffee' and [ b, a ] = [ a, b ] )

        # Add paths and join.
        merged = [ 'paths = ' + paths, a[1], b[1] ].join('\n')

        # Compile please, with closure.
        try
            js = cs.compile merged
        catch err
            return cb err

        # Merge the files into one and wrap in closure.
        cb null, js

# Write the client loader.
(loader, cb) ->
    write = (path, compress=false) ->
        (cb) ->
            try
                data = if compress then (uglify.minify(loader, 'fromString': true)).code else loader
            catch err
                return cb err

            fs.open path, 'w', 0o0666, (err, id) ->
                return cb err if err
                fs.write id, data, null, 'utf-8', (err) ->
                    return cb err if err
                    cb null

    async.parallel [
        write('./js/intermine.api.js')
        write('./js/intermine.api.min.js', true)
    ], cb

], (err) ->
    console.log (''+err).red if err