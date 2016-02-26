class Simultaneously
  constructor: (options = {}) ->
    @limit = options.limit || 20
    @tasks = []
    @results = []
    @collector = null
    @error_handler = null
    @scope = options.scope

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
          @execute_in_scope task, args
        @each()

  check_for_completion: (p) ->
    if @running == 0
      if @error
        if @error_handler
          @execute_in_scope @error_handler, [@error]
        else
          throw @error
      else if @left == 0
        @execute_in_scope @collector, [@results]

  execute_in_scope: (f, args) ->
    if @scope
      f.apply @scope, args
    else
      f args...

simultaneously = (options, f) ->
  unless f
    f = options
    options = {}
  p = new Simultaneously options
  if f.length == 0
    f.call p
  else
    f p
  p.run()

module.exports = simultaneously
