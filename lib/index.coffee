class Kevas extends (require 'stream').Transform
  constructor: (options) ->
    super options
    @_parse = opening
    if options?.values?
      values = options.values
      @on 'key', (key, push) ->
        push values[key] if values[key]?

  _transform: (string, encoding, next) ->
    string = string.toString 'utf8' # buffer becomes string, string returns itself
    parse = @_parse
    parse = parse(this, string) while parse?
    next()

  _flush: (done) -> #if @_parse is closing # TODO: log warning about an unclosed tag?
    @push keyOf this if this.__key?.length > 0
    done()

opening = (stream, string) ->
  stream._parse = opening
  start = 0
  for ch,i in string
    if ch is '\\' # if we see an escape character
      if stream.__slashIndex isnt (i - 1) # if previous character is NOT an escape character
        stream.push string[start...i] # push all content up to the character
        if i is string.length - 1
          stream.__slashIndex = -1
          return
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
        if i is string.length - 1 then stream._parse = openingDelim ; return
        else if string[i+1] is '{' then return -> closing stream, string[i+2..]
      else # the opening brace has been escaped, so, treat it like a regular char
        delete stream.__slashIndex #start++ # skip the slash tho because it was *used* to escape the brace

  if start < string.length then stream.push string[start..]
  return

closing = (stream, string) ->
  stream._parse = closing
  start = 0
  for ch,i in string
    if ch is '\\' # if we see an escape character
      if stream.__slashIndex isnt (i - 1) # if previous character is NOT an escape character
        keyOf stream, string[start...i] unless i is start # push all content up to the character
        if i is string.length - 1 then stream.__slashIndex = -1 ; return
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
          return
        else if string[i+1] is '}'
          key = keyOf stream
          stream.emit 'key', key, stream.push.bind(stream)
          return -> opening stream, string[i+2...]
      else # the opening brace has been escaped, so, treat it like a regular char
        delete stream.__slashIndex #start++ # skip the slash tho because it was *used* to escape the brace

  if start < string.length then keyOf stream, string[start..]
  return

openingDelim = (stream, string) -> delim stream, string, opening, '{', closing
closingDelim = (stream, string) -> delim stream, string, closing, '}', opening, (stream) ->
  key = keyOf stream
  stream.emit 'key', key, stream.push.bind(stream)

delim = (stream, string, continuing, char, switching, doKey) ->
  # we're starting with a delimeter from previous chunk
  if string[0] is char
    doKey? stream
    return -> switching stream, string[1..]
  else
    if doKey? then keyOf stream, char else stream.push char
    return -> continuing stream, string

keyOf = (stream, key) ->
  if key? then stream.__key = (stream.__key ? '') + key
  else
    key = stream.__key
    delete stream.__key
    return key

# Use three ways:
#  1. Kevas = require('kvstream').Kevas
#  2. kvstream = require('kvstream')
#     stream = kvstream(options)
#  3. stream = require('kvstream') (options)
module.exports = exporter = (options) -> new Kevas options
exporter.Kevas = Kevas
