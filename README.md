# kevas
[![Build Status](https://travis-ci.org/elidoran/node-kevas.svg?branch=master)](https://travis-ci.org/elidoran/node-kevas)
[![Dependency Status](https://gemnasium.com/elidoran/node-kevas.png)](https://gemnasium.com/elidoran/node-kevas)
[![npm version](https://badge.fury.io/js/kevas.svg)](http://badge.fury.io/js/kevas)


Stream replacing {{keys}} with values.

Think Mustache, but, streamed instead of loading the entire string into memory to process it.

Kevas : **KE**y **VA**lue **S**tream -> KE + VA + S

## Install

```sh
npm install kevas --save
```

## Usage: Simple

```coffeescript
kevas = require 'kevas'                   # get kevas
kvs = kevas values:key:'value'            # create with a key/value map
sourceStream.pipe(kvs).pipe(targetStream) # pipe text thru kevas to target
targetStream.on 'finish', ->              # do something when finished
  console.log 'all done, targetStream has it all...'
```

## Usage: More

```coffeescript
# 1. create a new stream and provide the key/value pairs to use for replacing
kevas = require('kevas') values:
  some:'value'
  an:'other'
  thing:'here'

# 2. and, you may provide an event listener to handle the keys.
# receives `event` which contains:
#   key: the key
#   values: an array to add values to which will be pushed to the stream
kevas.on 'key', (event) ->
  value = getValueForKey event.key
  if value? then event.values.push value
  else
    # do what you decide...

# 3. and, an event listener can do async work
kevas.on 'key', (event, next) ->
  getValueForKey event.key, (value) ->
    if value?
      event.values.push value
    else
      # do what you decide...
    # call next listener. provide the event
    next undefined, event

# pipe in the content with the keys and pipe out the result with value replacements.
someSource.pipe(kevas).pipe(someTarget)

# only want the keys from it? add a listener (like above) and then pipe the source in.

# have the source as a string? write it in:
kevas.pipe(someTarget)
kevas.write yourString, yourEncoding, callback
kevas.end()

# or turn the string into a stream and pipe it:
input = require('strung') 'your string content to pipe'
input.pipe(kevas)

# want the output as a string?
output = require('strung') ()
output.on 'finish', ->
  console.log 'result:',output.string
someSource.pipe(kevas).pipe(output)
```

## Example

```coffeescript
kevas  = require 'kevas'
strung = require 'strung'

# create our from/input/source stream, also used as to/output/target stream
strings = strung 'some {{okey}} is just as good as a {{lkey}}, right?'

# create a key/value object for the two methods of replacing keys.
internalValues = okey:'internal value'
listenerValues = lkey:'listener value'

# create our kevas instance which uses the internalValues
kvs = kevas values:internalValues

# add a key listener which uses the listenerValues
kvs.on 'key', (event) ->
  value = listenerValues[event.key]
  event.values.push value if value?

# add a listener for when the output is finished (as target, not on end as source)
strings.on 'finish', ->
  console.log 'result:',strings.string  

# finally pipe our string thru kevas and into a collecting stream
strings.pipe(kvs).pipe(strings)

#console :=>
# result: some internal value is just as good as a listener value, right?

# NOTE: if the key existed in both and both pushed then both values would
# be in the result.
```

## Listeners

Adding key listeners allows:

1. asynchronous operations to translate keys
2. override values submitted by previous listeners

Note, the first listener uses the internal values provided when the Kevas instance was created. So, to override the internal values, use a listener and remove that value from the result array: `event.values`.

## Escapes

Originally I was determined to avoid allowing escaped braces. Then, I decided I'd better allow it and added the functionality. It added some small work in the module.

Note, when putting an escape slash in a string you must type it twice or else the language will process it out of the string as an escape character it should handle.

So, `\\ -> \`. This will pass an escape slash on to `kevas` to handle. It will prevent a brace from being considered for wrapping a key. It will always be removed whether it's next to a brace or not.

And, `\\\\ -> \\`. This will pass on two escape slashes on to `kevas` to handle. The first escapes the second leaving a single slash in the `kevas` output.

`\\{{key}} -> {{key}}` First brace is escaped preventing a full wrapping so the key isn't processed.

`{\\{{{key}} -> {{value` First brace isn't part of an opening pair, so, it is passed on as is. Second brace is escaped so it is passed on as is (it's also what prevents the first from being part of a pair). Remaining braces wrap `key` so it is replaced with its value.

`{{key\\}}} -> value` The escaped closing brace isn't used as part of the closing pair so it becomes part of the *key*: `key}`.

`{{key}\\}}} -> value` The escaped closing brace prevents the first closing brace from being part of a pair. So, the first two closing braces become part of the key: `key}}`. The last two closing braces are the closing pair wrapping the key.


## Compatibility

Can this parse mustache templates? No? Yes? I think there are some variations between our parsing results. I intend to load some tests which run against the `mustache` module to monitor its functionality. Then, make a "mode" in options to have this adhere to mustache's parsing style.

Can this parse handlebars templates? No. This module only considers the contents of the `{{}}` to be a string representing the key for the value. Handlebars does more and has logic and other things in there. It's possible to get the keys via this module and do anything you'd like with them, so, treat them as a bit of code for Handlebars and you're all set.

## Why?

I made this module so I could use it to process files via streaming and replace keys with values as it streams.

I looked at `mustache` and `handlebars` and a few other modules. Each required loading the entire string to process it. And, most used regular expressions (I like regular expressions, just, not for this parsing task).

```coffeescript
# create a replacing stream referencing the key/value pairs we have.
kevas = require 'kevas', values:theValues

# pipe file through stream to a new file
sourceFile.pipe(kevas).pipe(targetFile)
```

### MIT License
