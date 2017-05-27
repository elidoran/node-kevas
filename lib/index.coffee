OPEN1  = 123 # {
OPEN2  = Buffer.from '{{'
CLOSE1 = 125 # }
CLOSE2 = Buffer.from '}}'
SLASH1 = 92  # \
SLASH2 = Buffer.from '\\\\'
SLASH  = Buffer.from '\\'

module.exports = (options) ->

  transform = null  # transform we're building now in this function
  buffer    = null  # will hold current buffer we're processing
  cache     = []    # caches chunks which make up the key
  cacheSize = 0     # number of bytes in cache for Buffer.concat()
  index     = 0     # where are we in the current buffer
  start     = 0     # where did the last unused content start
  target1   = OPEN1 # at start we're looking for open braces
  target2   = OPEN2
  hadSlash  = false # was there an unescaped slash at tail of previous buffer?
  hadTarget = false # was there an unescaped target1 at tail of previous buffer?
  getValues =       # the function to get a value for a key
    do (options) -> # either object or function in `options.values`
      # NOTE: had to explicitly return `undefined` in noops because
      #       coffee-coverage changed it to return a zero.
      unless options? and options.values? then return -> undefined # noop

      if typeof options.values is 'function' then options.values

      else if typeof options.values is 'object'
        values = options.values
        (key) -> values[key]

      else -> undefined # noop

  # `pushOrCache` changed for different modes. OPEN :> push CLOSE :> cache
  pushOrCache = doPush = (buffer) -> transform.push buffer

  doCache = (buffer) -> # CLOSE mode caches content to combine as a key
    cache.push buffer
    cacheSize += buffer.length

  # `switchTarget` changed for modes. OPEN :> toClose CLOSE :> toOpen
  switchTarget = toClose = ->
    # change what we're searching for and the mode based vars
    target1 = CLOSE1
    target2 = CLOSE2
    switchTarget = toOpen
    pushOrCache = doCache

    if start < index # if there's content before {{ then push it
      transform.push buffer.slice start, index

    # move passed pair and set the start there as well.
    start = index = index + 2
    return

  toOpen = ->
    # change what we're searching for and the mode based vars
    target1 = OPEN1
    target2 = OPEN2
    switchTarget = toClose
    pushOrCache = doPush

    if start < index # if there's content before }} then cache it
      slice = buffer.slice start, index
      cache.push slice
      cacheSize += slice.length

    # combine cache to get the "key" and reset cache vars
    key = Buffer.concat(cache, cacheSize).toString('utf8')
    cache.length = cacheSize = 0

    # try to get a value for the key
    value = getValues key

    # if there's a replacement value then push it
    if value? then transform.push value

    else # otherwise, push the original key with the braces around it
      transform.push OPEN2
      transform.push key
      transform.push CLOSE2

    # move passed pair and set the start there as well.
    start = index = index + 2
    return

  consumeSlash = -> # helper makes push/cache ops skip over a slash.
    # backup one from where we found a pair of braces to the slash.
    before = index - 1

    if start < before # if there's content before it then push/cache it.
      slice = buffer.slice start, before
      pushOrCache slice

    start = index # start after slash
    index++       # index moves after matched pair's first (escaped) brace
    return

  # build the transform using the convenience constructo
  transform = new require('stream').Transform

    # we're deoding strings so chunk is always a buffer so we ignore the encoding.
    transform: (chunk, _, done) ->
      buffer = chunk     # move it to our outer variable.
      index = start = 0  # reset the two indexing vars.

      # if we found a single targeted brace at the tail of the previous buffer
      # and this buffer starts with one then we've found the pair we wanted.
      if hadTarget is true and buffer[0] is target1
        switchTarget this, buffer, start, index
        # the above moves index/start by +2 which is usually right, but wrong now.
        # set to `1` to move passed the single target brace we used.
        index = start = 1

      # loop until we have no more buffer content to use
      while index < buffer.length

        # search for the next pair of braces from where we left off.
        index = buffer.indexOf target2, index

        # let's look at slash line-up to decide what to do and whether to
        # reinstate the hadSlash slash from the previous buffer.
        switch index

          when -1 # didn't find a pair in the rest of the buffer.
            escapePair   = false
            escapeEscape = false
            restoreSlash = hadSlash # maybe. if chunk length 1, target1 may be at 1

          when 0 # found the pair at the start of this buffer
            escapePair   = hadSlash
            escapeEscape = false
            restoreSlash = false

          when 1 # found the pair at 1 fo this buffer, check before it
            escapePair   = buffer[0] is SLASH1
            escapeEscape = hadSlash
            restoreSlash = false

          else # found the pair at 2 or greater, check before it
            escapePair   = buffer[index - 1] is SLASH1
            escapeEscape = buffer[index - 2] is SLASH1
            restoreSlash = hadSlash

        # reset this because we used it above
        hadSlash = false

        if index >= 0 # if we found a pair then we handle things like this:

          if restoreSlash then pushOrCache SLASH

          if escapePair # there's a slash before the braces, maybe escape them.

            if escapeEscape # there's a slash before the slash, so, it's escaped.

              if index > 1     # when both slashes are in the current buffer,
                consumeSlash() # then we consume the first one.
                index--        # then we backup one to keep one of them.

              switchTarget() # switch to searching for the other pair of braces

            else consumeSlash() # escaped the pair of braces so consume the slash

          else switchTarget() # no slashes, so, switch to searching for other braces

        else # check if tail end has some info, escape slash or target1...

          # reset these now to avoid a bunch of "else" statements.
          hadTarget = hadSlash = false

          # check the last bytes for a brace or slash
          last = buffer.length - 1

          switch buffer[last]

            when target1 # a lone brace we're looking for
              # TODO: if last is 0 ?

              if last is 1 # special case: 1st slash would be in previous buffer

                # `restoreSlash` tells if there was a slash in previous buffer
                if buffer[0] isnt SLASH1 or restoreSlash is true

                  # remember we matched a single target brace
                  hadTarget = true

                  # don't include our brace in the content handled at the bottom
                  buffer = buffer.slice 0, 1

              else # last >= 2 so we can check in buffer

                if buffer[last - 1] is SLASH1 # maybe escaped

                  if buffer[last - 2] is SLASH1 # escaped the slash instead
                    hadSlash = true
                    hadTarget = true
                    buffer = buffer.slice start, last - 1

                  else # is escaped, consume the slash, ignore the target1
                    pushOrCache buffer.slice start, last - 1  # no slash/target1
                    buffer = buffer.slice last, buffer.length # has target1

                else # we matched a single target brace
                  hadTarget = true

                  # don't include brace in the content handled at the bottom
                  buffer = buffer.slice start, last

            when SLASH1 # a lone slash may escape brace in next buffer's start.

              if buffer[last - 1] isnt SLASH1 # then it's not escaped

                # remember we had an unescaped escape slash.
                hadSlash = true

                # don't include the slash in our content
                buffer = buffer.slice start, last

            else # no target1 or slash at the end.

              # if there was a slash to restore then we restore it.
              # only happens if no pair is found in entire buffer.
              if restoreSlash then pushOrCache SLASH

              if start > 0 # limit what we'll push/cache
                buffer = buffer.slice start, buffer.length

          # handles buffer for current mode.
          pushOrCache buffer

          # we're done when we reach the swith's else
          return done()

        # tail of loop

      # we hit the end of the input buffer, loop stopped, we're done:
      done()


    flush: (done) ->      # if we were in CLOSE mode gathering a key,
      if hadSlash then @push SLASH

      if hadTarget then @push target2.slice(0, 1)

      if cache.length > 0 # then output what was cached no.
        @push OPEN2       # prepend the '{{' we found to switch mode to CLOSE.
        @push each for each in cache
        cache.length = cacheSize = 0  # reset the cache

      done()


  # way back up there we created `transform` which is the last thing so
  # it is returned from the exported function.
