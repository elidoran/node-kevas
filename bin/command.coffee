module.exports = (args, input, output) ->

  corepath = require 'path'
  nuc      = require 'nuc'
  buildValueStore = require 'value-store'

  # ouptput the version from the package.json file
  if '-v' in args or '--version' in args
    pkg = require corepath.join __dirname, '..', 'package.json'
    console.log "kevas v#{pkg.version}\n"
    return

  # see if there's an app id for `nuc` to use
  id = nuc.findId()

  # now build a value store either:
  values =
    # 1. directly, when there's no id, or, an error getting the id
    if not id? or id.__error? then buildValueStore [{}]

    # 2. via `nuc` when there is an id
    # NOTE: collapse into a single object.
    else nuc(id:id, collapse:true, stack:false).store


  # now, try to load each cli arg into the value store
  for arg in args

    # try it as a file path by having value store attempt to read it
    result = values.append arg

    # when there's no error then it was loaded so move on to the next one
    unless result?.error? then continue

    # otherwise, try to convert it to a key or key=value to put into values
    index = arg.indexOf '='
    if index < 0 then values.set arg, true
    else values.set arg[...index], arg[(index + 1)...]


  # build our kevas transform with key to value provider using our values
  kevas = require('../lib') values: (key) ->

    # get value from values store
    value = values.get key

    # if there's a value and it's not a string then convert it to one
    if value? and typeof value isnt 'string' then value = '' + value

    return value

  # setup pipeline
  input.pipe(kevas).pipe output
