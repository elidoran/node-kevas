corepath = require 'path'
nuc = require 'nuc'
buildValueStore = require('value-store')

# ouptput the version from the package.json file
if '-v' in process.argv or '--version' in process.argv
  pkg = require corepath.join __dirname, '..', 'package.json'
  console.log "kevas v#{pkg.version}\n"
  return process.exit()

# see if there's an app id for `nuc` to use
id = nuc.findId()

# now build a value store either:
values =
  # 1. directly, when there's no id
  if id?.__error? then buildValueStore()
  # 2. via `nuc` when there is an id
  else nuc id:id, collapse:false, stack:true

# now, try to load each cli arg into the value store
for arg in process.argv

  # try it as a file path by having value store attempt to read it
  result = values.append arg

  # when there's no error then it was loaded so move on to the next one
  unless result?.error? then continue

  # otherwise, try to convert it to a key or key=value to put into values
  index = arg.indexOf '='
  if index < 0 then values.set arg, true
  else values.set arg[...index], arg[(index + 1)...]


# build our kevas transform
kevas = require('../lib')()

# add a key to value translator using our values
kevas.on 'key', ->
  # get value from values store
  value = values.get @key

  # if there's a value and it's not a string then convert it to one
  if value? and typeof value isnt 'string' then value = '' + value

  # push the value or maintain the key in the content
  @values.push value ? ('{{' + @key + '}}')

  return

# setup pipeline
process.stdin.pipe(kevas).pipe process.stdout
