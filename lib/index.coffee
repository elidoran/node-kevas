async = require 'async'

class Kevas extends (require 'stream').Transform
  constructor: (options) ->
    super options
    @_parse = opening
    starter = (next) -> next undefined, key:starter.key, values:[]
    @_keyListeners = [starter]
    if options?.values?
      values = options.values
      @on 'key', (context) ->
        context.values.push values[context.key] if values[context.key]?

  _transform: (string, encoding, done) ->
    string = string.toString 'utf8' # buffer becomes string, string returns itself
    @_parser string, done

  _parser: (string, next) ->
    parse = @_parse
    parse = parse(this, string, next) while parse?

  _flush: (done) -> #if @_parse is closing # TODO: log warning about an unclosed tag?
    @push keyOf this if this.__key?.length > 0
    done()

  on: (event, listener) ->
    if event is 'key'
      if listener.length < 2 # then there's no callback arg. so, we want to call it for them
        listener = do(fn = listener) -> (context, next) ->
          try
            fn context
            next undefined, context
          catch error
            next error
      @_keyListeners ?= []
      @_keyListeners.push listener
    else super event, listener

  _emitKey: (key, done) ->
    # TODO: slice() array to make a copy?
    @_keyListeners[0].key = key
    async.waterfall @_keyListeners, (error, result) =>
      if error? then console.error 'key listeners error: ',error.message
      else
        @push value for value in result.values
        process.nextTick done


opening = (stream, string, done) ->
  stream._parse = opening
  start = 0
  for ch,i in string
    if ch is '\\' # if we see an escape character
      if stream.__slashIndex isnt (i - 1) # if previous character is NOT an escape character
        stream.push string[start...i] # push all content up to the character
        if i is string.length - 1
          stream.__slashIndex = -1
          return -> done()
        else
          stream.__slashIndex = i # record the index of this character
          start = i + 1 # move next start to this character
      else # there's a previous escape character *escaping* this one
        stream.push string[start...i-1] unless i is start # push all content before the first escape char
        start = i # move start to this character
        delete stream.__slashIndex # stop remembering slash because the pair counts as one slash now
    else if ch is '{'
      if stream.__slashIndex isnt (i - 1) # (when i=0, slashIndex may be -1 from previous chunk)
        stream.push string[start...i] unless start is i
        start = i
        if i is string.length - 1 then stream._parse = openingDelim ; return -> done()
        else if string[i+1] is '{' then return -> closing stream, string[i+2..], done
      else # the opening brace has been escaped, so, treat it like a regular char
        delete stream.__slashIndex #start++ # skip the slash tho because it was *used* to escape the brace

  if start < string.length then stream.push string[start..]
  return -> done()

closing = (stream, string, done) ->
  stream._parse = closing
  start = 0
  for ch,i in string
    if ch is '\\' # if we see an escape character
      if stream.__slashIndex isnt (i - 1) # if previous character is NOT an escape character
        keyOf stream, string[start...i] unless i is start # push all content up to the character
        if i is string.length - 1 then stream.__slashIndex = -1 ; return -> done()
        else
          stream.__slashIndex = i # record the index of this character
          start = i + 1 # move next start to this character
      else # there's a previous escape character *escaping* this one
        keyOf stream, string[start...i-1] # push all content before the first escape char
        start = i # move start to this character
        delete stream.__slashIndex # stop remembering slash because the pair counts as one slash now

    else if ch is '}'
      if stream.__slashIndex isnt (i - 1) # (when i=0, slashIndex may be -1 from previous chunk)
        keyOf stream, string[start...i] unless start is i
        start = i
        if i is string.length - 1
          stream._parse = closingDelim
          return -> done()
        else if string[i+1] is '}'
          return emitKey stream, string[i+2...], done
      else # the opening brace has been escaped, so, treat it like a regular char
        delete stream.__slashIndex

  if start < string.length then keyOf stream, string[start..]
  return -> done()

emitKey = (stream, string, done) ->
  key = keyOf stream
  #stream.emit 'key', key:key, values:[], next:-> opening stream, string
  stream._emitKey key, ->
    stream._parse = opening
    stream._parser string, done
  return

openingDelim = (stream, string, done) -> delim stream, string, done, opening, '{', closing, true
closingDelim = (stream, string, done) -> delim stream, string, done, closing, '}', emitKey, false

delim = (stream, string, done, continuing, char, switching, openingMode) ->
  # we're starting with a delimeter from previous chunk
  if string[0] is char
    return -> switching stream, string[1..], done
  else
    if openingMode then stream.push(char) else keyOf(stream, char)
    return -> continuing stream, string, done

keyOf = (stream, key) ->
  if key? then stream.__key = (stream.__key ? '') + key
  else
    key = stream.__key.trim()
    delete stream.__key
    return key

# Use three ways:
#  1. Kevas = require('kvstream').Kevas
#  2. kvstream = require('kvstream')
#     stream = kvstream(options)
#  3. stream = require('kvstream') (options)
module.exports = (options) -> new Kevas options
module.exports.Kevas = Kevas
