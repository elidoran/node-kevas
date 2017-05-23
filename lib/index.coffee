buildSearch = require 'stream-search-helper'
buildChain  = require 'chain-builder'

class Kevas extends (require 'stream').Transform

  constructor: (options) ->
    super options
    @_handleExtra = @_pushString
    @_search = buildSearch
      delim:/(\\{1,2})?({{|}})/
      min:4 # \\{{ is 4
      recurse:true # get all results at once from chunk
      groups:2 # two regex groups we want
    @_key = ''

    # if some `values` were provided
    if options?.values?

      # alias
      values = options.values

      # check if `values` has a get() function.
      # when it does, let's consider that the way to get the values
      if typeof values.get is 'function'
        @on 'key', ->
          value = values.get @key            # get the `value` from our `values`
          if value? # when exists, add to context's `values`, as a string
            if typeof value isnt 'string' then value = '' + value
            @values.push value

      else # otherwise, treat `values` as an object with keys
        @on 'key', -> if values[@key]? then @values.push values[@key]

    return


  _appendKey: (string) -> @_key += string  # accumulate key value

  _pushString: (string) -> @push string    # push strings to the next stream

  _combine: (result) ->
    delim = result.delim
    string = result.before
    result = switch delim.length
      when 2 then string             # just braces
      when 4 then string + '\\\\'    # escaped slashes are retained

    return result

  _transform: (string, encoding, done) ->

    string = string.toString 'utf8' # buffer becomes string, string returns itself
    results = @_search string
    @_parse results, done

  _parse: (results, done) ->

    while results.length > 0
      result = results.shift()

      # if it's a value before a found delim and it 'isn't escaped by a slash
      if result.before? and result.g1 isnt '\\'
        # what we do depends on the delim, more specifically, g2
        switch result.g2 # use `g2` instead of `delim` to ignore captured slashes

          when '{{'                      # string is before the start of a key
            @_handleExtra = @_appendKey  # for later strings, append to `key`
            string = @_combine result    # combine `.before` and delim part
            @push string                 # push the regular string

          when '}}'                        # string is before the end of a key
            if @_handleExtra is @_pushString
              # then the open braces were escaped, so, don't do key stuff
              @_pushString @_combine(result) + '}}'
            else
              @_handleExtra = @_pushString   # for later strings, push them
              key = @_key + @_combine result # get the accumulated key and emit it
              @_key = ''                     # reset key to empty string for appending
              return @_emitKey key.trim(), (error) =>
                if error? then done error
                else @_parse results, done

      # if it's a string without a delim after it, handle one of two ways:
      #  1. we're in non-key mode, so, it'll call _pushString
      #  2. we're in key mode, so, it'll call _appendKey
      else if result.string? then @_handleExtra result.string

      else # it found an escaped delim, so treat it like an extra string
        @_handleExtra result.before + result.g2

    # all done with results/chunk
    done()

  _flush: (done) -> # TODO: log warning about an unclosed tag?
    end = @_search.end()            # get anything left in the searcher
    @push end.string if end?.string?  # push it if there was something
    done()

  on: (event, listener) ->
    if event is 'key'
      unless @_chain?
        @_chain = buildChain array:[listener]
      else
        @_chain.add listener
    else super event, listener

  once: (event, listener) ->
    if event is 'key'
      fn = (control, context) =>
        result = listener control, context
        control.remove()
        return result
      @_chain.add fn
    else super event, listener # there are no other events we use...

  off: (event, listener) ->
    if event is 'key' then @_chain.remove listener
    else super event, listener # there are no other events we use...

  _emitKey: (key, done) ->
    context = key:key, values:[]
    @_chain?.run context:context, done:(error) =>
      if error? then return done error
      @push value for value in context.values
      process.nextTick done

# Use these ways:
#  1. buildKevas = require 'kevas'
#     stream = buildKevas options
#
#  2. stream = require('kevas') (options)
#
#  3a. {Kevas} = require 'kevas'
#  3b. Kevas = require('kevas').Kevas
#      stream = new Kevas some:'options'
module.exports = (options) -> new Kevas options
module.exports.Kevas = Kevas
