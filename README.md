# simultaneously

 Execute multiple asynchronous operations with limited concurrency.

 ```coffeescript
 fs = require 'fs'
 simultaneously = require 'simultaneously'

simultaneously ['file1', 'file2', 'file3'],
  each: (file, done) ->
    fs.copy file, 'dest/'+file, done
  then: (error) ->
    if error
      console.log "Something bad happened..."
    else
      console.log "All files copied!"
 ```
