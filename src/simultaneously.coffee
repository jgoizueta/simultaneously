# Execute multiple asynchronous operations
# with limited concurrency.
#
# Example:
# Assuming we have a funcion `load(image, callback)` that
# loads an image asynchronously and then calls callback:
#
#     concurrently = require 'concurrently'
#     images = ['img1.jpg', 'img2.jpg']
#     concurrently images,
#       limit: 10
#       each: (image, done) ->
#         load image
#         done()
#       then: (error) ->
#         console.log "All images have been loaded"
#
class Concurrently

  constructor: (elements, options, callback) ->
    unless callback?
      if typeof options is 'function'
        callback = options
        options = {}
    @elements = elements
    @callback = callback || options.then
    @limit = options.limit || 100
    @size = @elements.length
    @left = @size
    @running = 0
    @current = -1
    @error = null
    @each options.each if options.each?

  each: (processor) ->
    if !@error && @current < @size - 1
      if @running >= @limit
        setImmediate => @each processor
      else
        @running++
        @current += 1
        i = @current
        element = @elements[i]
        do (i) =>
          processor element, (error) =>
            @running--
            @left--
            @error ||= error
            @check_for_completion()
        @each processor

  check_for_completion: (p) ->
    if @running == 0 && (@error || @left == 0)
      @callback @error

module.exports = (elements, options, callback) ->
  new Concurrently(elements, options, callback)
