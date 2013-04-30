#!/usr/bin/env coffee
assert        = require 'assert'
async         = require 'async'
{ intermine } = require '../js/intermine.api.js'

module.exports =  
    'Same resource in parallel': (done) ->
        i = 0
        # Replace with our custom async-loader script.
        intermine.loader = (path, type, cb) ->
            i++
            process.nextTick cb

        load = (deps) -> (cb) -> intermine.load deps, cb

        async.parallel [
            load({ 'test': { 'A': { 'path': 'A1' } } })
            load({ 'test': { 'A': { 'path': 'A2' } } })
        ], (err, results) ->
            assert.equal i, 1, '`loader` was not called just once'
            done()

    'Array-style loading (deprecated)': (done) ->
        order = []

        # Replace with our custom async-loader script.
        intermine.loader = (path, type, cb) ->
            order.push path
            process.nextTick cb

        i = 0
        intermine.load [
            { 'name': 'A', 'path': 'A', 'type': 'css' }
            { 'name': 'B', 'path': 'B', 'type': 'js' }
            { 'name': 'C', 'path': 'C', 'type': 'js', 'wait': true }
            { 'name': 'D', 'path': 'D', 'type': 'js', 'wait': true }
            { 'name': 'E', 'path': 'E', 'type': 'js', 'wait': true }
        ], ->
            i++
            assert.equal i, 1, 'called back more than once'
            assert.equal order.length, 5, 'not all resources have been called'

            # Check the order.
            [ A, B, C, D, E ] = order
            if A is 'B' then [ A, B ] = [ B, A ] # with the first two we can't be sure

            # Now we want to equal baby.
            for [ actual, expected ] in [ [ A, 'A' ], [ B, 'B' ], [ C, 'C' ], [ D, 'D' ], [ E, 'E' ] ]
                assert.equal actual, expected

            done()

    # 'Auto-resolve dependencies among each other': (done) ->
    #     done()

    # 'Named resource loading (deprecated)': (done) ->
    #     done()

    # 'Do not load resources on the `window`': (done) ->
    #     done()

    # 'Do not load resources that pass a `check`': (done) ->
    #     done()