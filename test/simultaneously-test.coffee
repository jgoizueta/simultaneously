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
        callback()
      @on_error (error) ->
        assert.equal 'error', error
        callback()

  check_errors_abort = (n, limit, callback) ->
    data = (i for i in [1..n])
    error_i = n/2
    simultaneously limit: limit, ->
      @execute_for data, (i, done) ->
        if i == error_i
          done i
        else
          assert.ok i < n/2
          done null
      @collect ->
        assert.ok false
        callback()
      @on_error (error) ->
        assert.equal error, error_i
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

  check_all_processed_sync_block = (n, limit, callback) ->
    data = (i for i in [1..n])
    simultaneously limit: limit, (block) ->
      block.execute_for data, (i, done) -> done null, i
      block.collect (results) ->
        assert.deepEqual data, results
        callback()

  check_all_processed_async_block = (n, limit, callback) ->
    data = (i for i in [1..n])
    simultaneously limit: limit, (block) ->
      block.execute_for data, (i, done) ->
        setTimeout (-> done null, i), 20 + Math.random(90)
      block.collect (results) ->
        assert.deepEqual data, results
        callback()

  check_errors_block = (n, limit, callback) ->
    data = (i for i in [1..n])
    simultaneously limit: limit, (block) ->
      block.execute_for data, (i, done) ->
        if i == 1 + Math.floor(i/2)
          done 'error'
        else
          done null
      block.collect ->
        assert.ok false
        callback()
      block.on_error (error) ->
        assert.equal 'error', error
        callback()

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

  for [n, limits] in [ [10, [5, 10, 11, 15]], [2, [2, 1]], [300, [5, 1, 100, 300, 400]] ]
    for limit in limits
      it "should abort on error for #{n} elements, limit #{limit}", (done) ->
        check_errors_abort n, limit, done

  it "should be callable without options", (done) ->
    simultaneously ->
      @execute (done) ->
        assert.ok true
        done null, 'value'
      @collect (results) ->
        assert.deepEqual results, ['value']
        done()

  it "should be able to define the scope for tasks", (done) ->
    @_outer_value = 1234
    simultaneously scope: this, ->
      @execute (done) ->
        assert.equal @_outer_value, 1234
        done null
      @collect ->
        assert.equal @_outer_value, 1234
        done()

  it "should be able to define the scope for the error handler", (done) ->
    @_outer_value = 1234
    simultaneously scope: this, ->
      @execute (done) ->
        assert.equal @_outer_value, 1234
        done 'error'
      @on_error ->
        assert.equal @_outer_value, 1234
        done()
      @collect ->
        assert.ok false
        done()

  for [n, limits] in [ [10, [5, 10, 11, 15]], [2, [2, 1]], [300, [5, 1, 100, 300, 400]] ]
    for limit in limits
      it "should use a block parameter sync", (done) ->
        check_all_processed_sync_block n, limit, done
      it "should use a block parameter async", (done) ->
        check_all_processed_async_block n, limit, done
      it "should use a block parameter errors", (done) ->
        check_errors_block n, limit, done

  it "should preserve this scope if function accepts block parameter", (done) ->
    @_outer_value = 1234
    simultaneously (block) =>
      block.execute (done) =>
        assert.equal @_outer_value, 1234
        done 'error'
      block.on_error =>
        assert.equal @_outer_value, 1234
        done()
      block.collect =>
        assert.ok false
        done()
