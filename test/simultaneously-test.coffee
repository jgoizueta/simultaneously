assert = require "assert"

describe 'simultaneously', ->
  simultaneously = require '../lib/simultaneously'

  check_all_processed_sync = (n, limit, callback) ->
    data = (i for i in [1..n])
    simultaneously limit: limit, ->
      @execute_for data, (i, done) -> done null, i
      @collect (results) ->
        assert.deepEqual data, results
        callback()

  check_all_processed_async = (n, limit, callback) ->
    data = (i for i in [1..n])
    simultaneously limit: limit, ->
      @execute_for data, (i, done) ->
        setTimeout (-> done null, i), 20 + Math.random(90)
      @collect (results) ->
        assert.deepEqual data, results
        callback()

  check_concurrency_limit = (n, limit, callback) ->
    data = (i for i in [1..n])
    max_concurrency = 0
    concurrent = 0
    simultaneously  limit: limit, ->
      @execute_for data, (i, done) ->
        concurrent++
        max_concurrency = concurrent if concurrent > max_concurrency
        setTimeout ->
          concurrent--
          done null
        , 35
      @collect ->
        assert.ok max_concurrency <= limit
        callback()

  check_errors = (n, limit, callback) ->
    data = (i for i in [1..n])
    simultaneously limit: limit, ->
      @execute_for data, (i, done) ->
        if i == 1 + Math.floor(i/2)
          done 'error'
        else
          done null
      @collect ->
        assert.ok false
      @on_error (error) ->
        assert.equal 'error', error
        callback()

  check_no_errors = (n, limit, callback) ->
    data = (i for i in [1..n])
    simultaneously limit: limit, ->
      @execute_for data, (i, done) ->
        done null, i
      @collect ->
        assert.ok true
        callback()
      @on_error (error) ->
        assert.ok false

  for [n, limits] in [ [10, [5, 10, 11, 15]], [2, [2, 1]], [300, [5, 1, 100, 300, 400]] ]
    for limit in limits
      it "should process synchronously all data for #{n} elements, limit #{limit}", (done) ->
        check_all_processed_sync n, limit, done

  for [n, limits] in [ [10, [5, 10, 11, 15]], [2, [2, 1]], [300, [5, 1, 100, 300, 400]] ]
    for limit in limits
      it "should process asynchronously all data for #{n} elements, limit #{limit}", (done) ->
        check_all_processed_async n, limit, done

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
