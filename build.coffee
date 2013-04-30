fs      = require 'fs'
cs      = require 'coffee-script'
yaml    = require 'js-yaml'
winston = require 'winston'
async   = require 'async'

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

# Load the loader & compile.
(paths, cb) ->
    fs.readFile 'loader.coffee', 'utf-8', (err, data) ->
        return cb err if err
        try
            js = cs.compile data, 'bare': 'on'
            cb null, "(function() {\n#{js}\nintermine.resources = #{paths};\n}).call(this);"
        catch err
            return cb err

# Write the client loader.
(loader, cb) ->
    fs.open './js/intermine.api.js', 'w', 0o0666, (err, id) ->
        return cb err if err
        fs.write id, loader, null, 'utf-8', (err) ->
            return cb err if err
            cb null

], (err) ->
    console.log (''+err).red if err