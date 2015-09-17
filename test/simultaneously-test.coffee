assert = require "assert"

describe 'simultaneously', ->
  simultaneously = require '../simultaneously'

  check_all_processed = (n, limit, callback) ->
    data = (i for i in [1..n])
    processed = []
    simultaneously data,
      limit: limit
      each: (i, done) ->
        processed.push i
        done()
      then: ->
        assert.deepEqual data, processed.sort (a, b) -> a - b
        callback()

  check_concurrency_limit = (n, limit, callback) ->
    data = (i for i in [1..n])
    max_concurrency = 0
    concurrent = 0
    simultaneously data,
      limit: limit
      each: (i, done) ->
        concurrent++
        max_concurrency = concurrent if concurrent > max_concurrency
        setTimeout ->
          concurrent--
          done()
        , 35
      then: ->
        assert.ok max_concurrency <= limit
        callback()

  check_errors = (n, limit, callback) ->
    data = (i for i in [1..n])
    simultaneously data,
      limit: limit
      each: (i, done) ->
        if i == 1 + Math.floor(i/2)
          done 'error'
        else
          done()
      then: (error) ->
        assert.equal 'error', error
        callback()

  check_no_errors = (n, limit, callback) ->
    data = (i for i in [1..n])
    simultaneously data,
      limit: limit
      each: (i, done) ->
        done()
      then: (error) ->
        assert.ok !error
        callback()

  for [n, limits] in [ [10, [5, 10, 11, 15]], [2, [2, 1]], [300, [5, 1, 100, 300, 400]] ]
    for limit in limits
      it "should process all data for #{n} elements, limit #{limit}", (done) ->
        check_all_processed n, limit, done

  for [n, limits] in [ [10, [5, 10, 11, 15]], [2, [2, 1]], [300, [5, 1, 100, 300, 400]], [1000, [1, 2, 100]] ]
    for limit in limits
      it "should not surpass concurrency limit for #{n} elements, limit #{limit}", (done) ->
        check_concurrency_limit n, limit, done

  for [n, limits] in [ [10, [5, 10, 11, 15]], [2, [2, 1]], [300, [5, 1, 100, 300, 400]] ]
    for limit in limits
      it "should pass errors for #{n} elements, limit #{limit}", (done) ->
        check_errors n, limit, done

  for [n, limits] in [ [10, [5, 10, 11, 15]], [2, [2, 1]], [300, [5, 1, 100, 300, 400]] ]
    for limit in limits
      it "should not generate false errors for #{n} elements, limit #{limit}", (done) ->
        check_no_errors n, limit, done
