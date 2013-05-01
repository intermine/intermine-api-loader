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
            assert.ifError err
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
        ], (err) ->
            assert.ifError err
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

    'Auto-resolve dependencies among each other': (done) ->
        order = []

        # Replace with our custom async-loader script.
        intermine.loader = (path, type, cb) ->
            order.push path
            process.nextTick cb

        intermine.load
            'js':
                'D': { 'path': 'D', 'depends': [ 'C' ] }
                'A': { 'path': 'A' }
                'C': { 'path': 'C', 'depends': [ 'A' ] }
                'B': { 'path': 'B' }
        , (err) ->
            assert.ifError err

            # Check the order.
            [ A, B, C, D ] = order
            if A is 'B' then [ A, B ] = [ B, A ] # with the first two we can't be sure (we can)

            # Now we want to equal baby.
            for [ actual, expected ] in [ [ A, 'A' ], [ B, 'B' ], [ C, 'C' ], [ D, 'D' ] ]
                assert.equal actual, expected

            done()

    'Depending on a non-existent entry': (done) ->
        # Replace with our custom async-loader script.
        intermine.loader = (path, type, cb) ->
            assert false, 'should have skipped'
            process.nextTick cb

        intermine.load
            'js':
                'B': { 'path': 'B', 'depends': [ 'X' ] }
                'A': { 'path': 'A' }
        , (err) ->
            assert.equal err, 'Unrecognized dependency `X`'
            done()

    'Depending on a non-string entry': (done) ->
        # Replace with our custom async-loader script.
        intermine.loader = (path, type, cb) ->
            assert false, 'should have skipped'
            process.nextTick cb

        intermine.load
            'js':
                'B': { 'path': 'B', 'depends': [ 'A', -> ] }
                'A': { 'path': 'A' }
        , (err) ->
            assert.equal err, 'Unrecognized dependency `function () {}`'
            done()

    'A circular dependency hell': (done) ->
        # Replace with our custom async-loader script.
        intermine.loader = (path, type, cb) ->
            assert false, 'should have skipped'
            process.nextTick cb

        intermine.load
            'js':
                'F': { 'path': 'F', 'depends': [ 'G', 'H', 'I' ] }
                'A': { 'path': 'A', 'depends': [ 'B', 'C' ] }
                'B': { 'path': 'B', 'depends': [ 'D', 'A' ] }
                'J': { 'path': 'J', 'depends': [ 'F', 'K' ] }
                'C': { 'path': 'C', 'depends': [ 'E' ] }
                'E': { 'path': 'E', 'depends': [ 'F' ] }
                'I': { 'path': 'I', 'depends': [ 'J' ] }
                'K': { 'path': 'K', 'depends': [ 'L' ] }
                'D': { 'path': 'D' }
                'G': { 'path': 'G' }
                'H': { 'path': 'H' }
                'L': { 'path': 'L' }
        , (err) ->
            assert.equal err, 'Circular dependencies detected for `F,A,B,J,I`'
            done()

    # 'Named resource loading (deprecated)': (done) ->
    #     done()

    # 'Do not load resources on the `window`': (done) ->
    #     done()

    # 'Do not load resources that pass a `check`': (done) ->
    #     done()