# kevas
[![Build Status](https://travis-ci.org/elidoran/node-kevas.svg?branch=master)](https://travis-ci.org/elidoran/node-kevas)
[![Dependency Status](https://gemnasium.com/elidoran/node-kevas.png)](https://gemnasium.com/elidoran/node-kevas)
[![npm version](https://badge.fury.io/js/kevas.svg)](http://badge.fury.io/js/kevas)
[![Coverage Status](https://coveralls.io/repos/github/elidoran/node-kevas/badge.svg?branch=master)](https://coveralls.io/github/elidoran/node-kevas?branch=master)

Stream replacing {{keys}} with values.

Think Mustache, but, streamed instead of loading the entire string into memory to process it.

kevas = **ke** y **va** lue **s** tream => ke + va + s


## Install

Install as a local library or globally as a CLI.

```sh
npm install --save kevas

# for `kevas` CLI
npm install -g kevas
```


## Memory Usage

I looked at multiple implementations of this and found they read the entire content into a single string before processing it. This implementation retains as little content as possible in memory between `_transform()` calls.


## Usage: Build it

```javascript
// build methods:

// 1. get the builder function and use it separately
var buildKevas = require('kevas')
var kevas = buildKevas()

// 2. get the builder function and use it at once
var kevas = require('kevas')()


// Two methods of providing values at build time:

// 1. Provide an object:
var values = {}

var options = { values: values }

var kevas = buildKevas(options)

// 2a. Provide a `get(key)` function:
var valuesObject = {}

var options = {
  values: function get(key) {
    return valuesObject[key]
  }
}

var kevas = buildKevas(options)

// 2b. 'value-store' has a get(key) function:
var buildValueStore = require('value-store')

var valueStore = buildValueStore()

var options = {
  values: function get(key) {
    return valueStore.get(key)
  }
}

var kevas = buildKevas(valueStore)
```


## Usage: Example

```javascript
var buildKevas = require('kevas')

var values = { key: 'value' }

var kevas = buildKevas({ values: values })

var source = getSomeReadableStream()
var target = getSomeWritableStream()

// pipe content through `kevas` to replace the keys
source.pipe(kevas).pipe(target)

// do something when finished processing the stream
target.on('finish', function () {
  console.log('all done, target stream has it all...')
})

// if the source stream provided:
//   'test some {{key}} in kevas'
// then the target stream would receive:
//   'test some value in kevas'

// or, write strings directly to the `kevas` instance
kevas.write('test some {{key}} in kevas')
```


## Usage: CLI

The `kevas` cli reads input from `stdin` and writes transformed content to `stdout`.

Provide values via multiple methods provided by modules [nuc](https://npmjs.com/package/nuc) and [value-store](https://npmjs.com/package/value-store).

1. provide keys as arguments and they will be used as `key=true`
2. provide key/value pairs as arguments like `key=value`
3. provide file paths as arguments and they'll be loaded into a [value-store](https://npmjs.com/package/value-store). Note, they are checked in order, so, earlier files will override values in later files
4. access configuration files for an app ID you provide on the command line, or via other [nuc](https://npmjs.com/package/nuc) methods.

Examples of key and key=value args:

```sh
# read a file, replace its keys, write to console
cat input.file | kevas one=1 two=2 three=3 result

# when 'input.file' contains:
testing shows: {{one}} + {{two}} = {{three}} is {{result}}

# then the console prints:
testing shows: 1 + 2 = 3 is true
```

Example of loading a JSON file with the same values as the above example. Note, you may also use INI files.

First, the JSON file at `some/values/file.json`:

```json
{
  "one"   : 1,
  "two"   : 2,
  "three" : 3,
  "result": true
}
```

Now, run the command for the same results as above:

```sh
cat input.file | kevas some/values/file.json

# with the same input file it will print the same output as above:
testing shows: 1 + 2 = 3 is true
```

To use [nuc](https://npmjs.com/package/nuc) loaded values requires a bit more.

Provide an app id to `nuc` via:

1. command line arg: `--NUCID=someId`
2. a '.nuc.name' file in the current working directory with the app ID as its only content
    ```
    someId
    ```

Example with command line arg:

```sh
cat input.file | kevas --NUCID=someId
```

Example using a `.nuc.name` file:

```sh
# make a .nuc.name file with the id:
echo "someId" > .nuc.name

# set the values via nuc.
# 'local' scope makes it create a local file to set into
# file: someId.json
# then, later calls will find and use that file.
nuc set one 1 local
nuc set two 2
nuc set three 3
nuc set result true

# then make the call and nuc will find .nuc.name and lookup those values
cat input.file | kevas

# that command will print the same output shown in all the examples:
testing shows: 1 + 2 = 3 is true

# use nuc to alter the values
nuc set one some
nuc set two thing
nuc set three something
nuc set result a nonesense example

# rerun kevas
cat input.file | kevas

# prints:
testing shows: some + thing = something is a nonsense example
```

Review the [nuc](https://npmjs.com/package/nuc) module to see all it has to offer. It allows a hierarchy of configuration files to make use of environment specific configurations and global/system/user level config files.


## Escapes

Simplified escaping: an unescaped escape slash before the first of a pair of braces will escape that pair.

So, `\{{` is escaped and `\\{{` is not. When writing a string in code we must escape the escape slash so it looks like `\\{{` to provide escaping content and `\\\\{{` to escape the escape slash.


## Compatibility

Can this parse mustache templates? No? Yes? I think there are some variations between our parsing results. I have yet to make a comparison.

Can this parse handlebars templates? No. This module only considers the contents of the `{{}}` to be a string representing the key for the value. Handlebars does more and has logic and other things in there. It's possible to get the keys via this module and do anything you'd like with them, so, treat them as a bit of code for Handlebars and you're all set.


## Why?

I made this module so I could use it to process files via streaming and replace keys with values as it streams.

I looked at `mustache` and `handlebars` and a few other modules. Each required loading the entire string to process it. And, most used regular expressions (I like regular expressions, just, not for this parsing task).

A stream may remain open and receive new content over time to parse, replace keys, and push on. It's possible to setup a stream which sends messages, maybe log messages, to another machine and replaces special tags with information on its way out.


# [MIT License](LICENSE)
