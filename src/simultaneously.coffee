class Simultaneously
  constructor: (options = {}) ->
    @limit = options.limit || 20
    @tasks = []
    @results = []
    @collector = null
    @error_handler = null

  execute: (args...) ->
    task = args.pop()
    @tasks.push [task, args]
    @results.push null

  execute_for: (collection, task) ->
    @execute item, task for item in collection

  collect: (collector) ->
    @collector = collector

  on_error: (eh) ->
    @error_handler = eh

  run: ->
    @size = @tasks.length
    @left = @size
    @running = 0
    @current = -1
    @error = null
    @each()

  each: ->
    if !@error && @current < @size - 1
      if @running >= @limit
        setImmediate => @each()
      else
        @running++
        @current += 1
        i = @current
        [task, args] = @tasks[i]
        do (i) =>
          args.push (error, result) =>
            @running--
            @left--
            @error ||= error
            @results[i] = result
            @check_for_completion()
          task args...
        @each()

  check_for_completion: (p) ->
    if @running == 0
      if @error
        @error_handler? @error
      else if @left == 0
        @collector @results

simultaneously = (options, f) ->
  unless f
    f = options
    options = {}
  p = new Simultaneously options
  f.call p
  p.run()

module.exports = simultaneously
