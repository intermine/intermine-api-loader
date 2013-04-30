fs      = require 'fs'
cs      = require 'coffee-script'
yaml    = require 'js-yaml'
winston = require 'winston'
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

        # Swap order?
        if results[0][0] is 'loader.coffee' then results = [ results[1], results[0] ]

        # Compile please.
        try
            js = cs.compile [ results[0].pop(), results[1].pop() ].join('\n'), 'bare': 'on'
        catch err
            return cb err

        # Shift them by 2 notches.
        js = ( '  ' + line for line in js.split('\n') ).join('\n')

        # Merge the files into one and wrap in closure.
        cb null, "(function() {\n#{js}\nintermine.resources = #{paths};\n}).call(this);"

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