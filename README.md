# simultaneously

#### Execute multiple asynchronous operations with limited concurrency.

[![NPM](https://nodei.co/npm/simultaneously.png)](https://nodei.co/npm/simultaneously/)

This is intended to be used from CoffeScript, as it takes advantage
of that language's syntax. Other modules such as
[Async](https://www.npmjs.com/package/async) (`async.parallel`) or
[Step](https://www.npmjs.com/package/step) (using `this.parallel`)
are probably a better match for JavaScript.

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

The solution: use `simultaneously` passing a function to it.
Inside the function (which is executed with a special `this`
value) you can call `@execute` to define tasks to be executed
parallelly. Each task must finish calling the `done` parameter
which is passed to it; the first argument to `done` is
and error object to be used in the case of error, and you
can pass an additional parameter to send results which will be collected later.
Using `@collect` you can define an action to be executed when
all the tasks finish, and which will receive an array with all
the results of the tasks. The results appear in this array in the
order of definition of the corresponding tasks.
The `@on_error` method can be used set up a function that
will be called in the case of error.

```coffeescript
fs = require 'fs'
simultaneously = require 'simultaneously'

simultaneously ->
  @execute (done) -> fs.copy 'file1', 'dest/file1', done
  @execute (done) -> fs.copy 'file2', 'dest/file1', done
  @execute (done) -> fs.copy 'file3', 'dest/file1', done
  @collect -> do_something_after_all_files_are_copied()
  @on_error (error) -> handle_the_error error
```

This example could have been written also as:

```coffeescript
fs = require 'fs'
simultaneously = require 'simultaneously'
files_to_be_copied = ['file1', 'file2', 'file3']

simultaneously ->
  @execute_for files_to_be_copied, (file, done) ->
    fs.copy file, 'dest/'+file, done
  @collect -> do_something_after_all_files_are_copied()
  @on_error (error) -> handle_the_error error
```

Note that you can use any number of `@execute` and `@execute_for`
definitions inside a `simultaneously` block.

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

simultaneously limit: 100, ->
  @execute_for lots_of_files, (file, done) ->
    fs.copy file, 'dest/'+file, done
  @collect -> do_something_after_all_files_are_copied()
  @on_error (error) -> handle_the_error error
```

## Scope

If you need to access the outer scope (`this`) from
the tasks or error handler you can pass it through
the `scope` option and it will become the `this`
value when task or error handlers are executed:

```coffeescript
@value = 10 # will need to use this...
simultaneously scope: this, ->
  @execute (done) ->
    # Now this has the same value as in the scope enclosing Simultaneously
    console.log @value # => 10
    done null
  @collect  ->
    # ... and here too:
    console.log @value # => 10
  @handle_error (err) ->
    # ... or here:
    console.log @value # => 10
```

## More examples

```coffeescript
simultaneously limit: 8, ->
  @execute (done) ->
    download_file 'url', (error, data) ->
      done error, data
  @execute_for [1..10], (i, done) ->
    download_file "url_#{i}", (error, data) ->
    done error, data
  @collect (results) ->
    console.log "concatenated files", results.join('')
  @handle_error (err) ->
    console.log "an error ocurred:", err
```

```coffeescript
fs = require 'fs'
parallelly = require 'parallelly'

files_to_be_copied = ['file1', 'file2', 'file3']

simultaneously ->
  @execute_for files_to_be_copied, (file, done) ->
    # Process each element, then call `done()`
    fs.copy file, 'dest/'+file, done
  @collect ->
    do_something_after_all_files_are_copied()
  @on_error (error) ->
    handle_the_error error
```
