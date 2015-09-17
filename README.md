# simultaneously

Execute multiple asynchronous operations with limited concurrency.

This module is written in CoffeeScript and examples are given
in that language. JavaScript use examples are left as
an exercise for the reader.

## Example

The problem: yo have a nice asynchronous function, say `fs.copy`,
which you can use like this:

```coffeescript
fs = require 'fs'

fs.copy 'file', 'dest/file', ->
  do_something_after_file_is_copied()
```

But you need to use the function on multiple entities
(files in our example) and do something else when
*all* the entities have been processed.

```coffeescript
fs = require 'fs'

files_to_be_copied = ['file1', 'file2', 'file3']
for file in files_to_be_copied
  fs.copy file, 'dest/'+file, ->
    # file has been copied
# ... ?
```

The solution: using `simultaneously`
you provide an `each` function to Process
each element. This function receives the element to be processed
and a callback that must be called when the processing is complete.
You pass an `error` object to that callback if an error occurred.

You also provide a `then` function that will be called when
the processing is complete for all elements or an error has occurred
(the error object will be passed as an argument).

 ```coffeescript
fs = require 'fs'
simultaneously = require 'simultaneously'

files_to_be_copied = ['file1', 'file2', 'file3']

simultaneously files_to_be_copied,
  each: (file, done) ->
    # Process each element, then call `done()``
    fs.copy file, 'dest/'+file, done
  then: (error) ->
    if error
      handle_the_error error
    else
      do_something_after_all_files_are_copied()
```

## Limit

When you need to process many entities you'll probably want
to limit how many of them are processed simultaneously.

Failing to do so in our example may surpass the maximum
number of open files allowed.

The `limit` parameter defines the maximum number of
concurrent processes that can be in execution at
the same time. By default has a value of 20.

Here we will copy *many* files, but won't
handle more than 100 of them at a time:

```coffeescript
fs = require 'fs'
simultaneously = require 'simultaneously'

lots_of_files = ("file#{i}" for i in [1..1000000])

simultaneously files_to_be_copied,
  limit: 100
  each: (file, done) ->
    # Process each element, then call `done()``
    fs.copy file, 'dest/'+file, done
  then: (error) ->
    if error
      handle_the_error error
    else
      do_something_after_all_files_are_copied()
```
