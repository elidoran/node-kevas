# kevas
[![Build Status](https://travis-ci.org/elidoran/node-kevas.svg?branch=master)](https://travis-ci.org/elidoran/node-kevas)
[![Dependency Status](https://gemnasium.com/elidoran/node-kevas.png)](https://gemnasium.com/elidoran/node-kevas)
[![npm version](https://badge.fury.io/js/kevas.svg)](http://badge.fury.io/js/kevas)

Stream replacing {{keys}} with values.

Think Mustache, but, streamed instead of loading the entire string into memory to process it.

Kevas : **KE**y **VA**lue **S**tream -> KE + VA + S

**Version 3.0.0 almost ready**

It updates how it processes, adds a cli for transforming on the console, and will change this README to JavaScript.


## Install

```sh
npm install kevas --save
```

## Usage: Simple

```coffeescript
kevas = require('kevas') values:key:'value'   # create kevas with a key/value map
source.pipe(kevas).pipe(target)        # pipe text thru kevas to target
target.on 'finish', ->                 # do something when finished
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
buildKevas  = require 'kevas'
strung = require 'strung'

# create our from/input/source stream, also used as to/output/target stream
strings = strung 'some {{okey}} is just as good as a {{lkey}}, right?'

# create a key/value object for the two methods of replacing keys.
internalValues = okey:'internal value'
listenerValues = lkey:'listener value'

# create our kevas instance which uses the internalValues
kevas = buildKevas values:internalValues

# add a key listener which uses the listenerValues
kevas.on 'key', (event) ->
  value = listenerValues[event.key]
  event.values.push value if value?

# add a listener for when the output is finished (as target, not on *end* as source)
strings.on 'finish', ->
  console.log 'result:',strings.string  

# finally pipe our string thru kevas and into a collecting stream
strings.pipe(kevas).pipe(strings)

#console :=>
# result: some internal value is just as good as a listener value, right?

# NOTE: if the key existed in both, and both pushed their value, then both values would
# be in the result.

# NOTE: the later listener can see previously provided values in
# `event.values` array, and can remove or edit them.
```

## Creating Kevas instance

```coffeescript
# 1. direct at require time
kevas = require('kevas') keyValueObject

# 2. from required builder function
buildKevas = require 'kevas'
kevas      = buildKevas keyValueObject

# 3. from Kevas class
{Kevas} = require 'kevas'
kevas   = new Kevas keyValueObject
```

For JavaScript without destructuring assignments:
```JavaScript
var Kevas = require('kevas').Kevas
var kevas = new Kevas(keyValueObject)
```

## Listeners

Adding key listeners allows:

1. asynchronous operations to translate keys
2. override values submitted by previous listeners

Note, the first listener uses the internal values provided when the Kevas instance was created. So, to override the internal values, use a listener and remove that value from the result array: `event.values`.

## Escapes

Originally I was determined to avoid allowing escaped braces. Then, I decided I'd better allow it and added the functionality.
It's a pain to implement, so, I've simplified it. An escape slash before the first of a pair of braces will escape that pair.

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
