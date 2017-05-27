assert = require 'assert'
buffed = require 'buffed'
strung = require 'strung'
join   = require('path').join

command = require '../../bin/command.coffee'

sourceContent = 'some {{key}} content'
sourceBuffer  = Buffer.from sourceContent

describe 'test kevas cli', ->

  it 'with --version', ->

    log = console.log
    console.log = (s) ->
      assert.equal s, 'kevas v4.0.0\n'
      console.log = log

    command ['--version']

  it 'with -v', ->

    log = console.log
    console.log = (s) ->
      assert.equal s, 'kevas v4.0.0\n'
      console.log = log

    command ['-v']


  it 'with no args', (done) ->

    stream = buffed sourceBuffer
    stream.on 'error', done
    stream.on 'finish', ->
      assert.equal stream.combine().toString(), sourceContent
      done()

    command [], stream, stream


  it 'with key as arg', (done) ->

    stream = buffed sourceBuffer
    stream.on 'error', done
    stream.on 'finish', ->
      assert.equal stream.combine().toString(), sourceContent.replace '{{key}}', 'true'
      done()

    command ['key'], stream, stream


  it 'with key=value as arg', (done) ->

    stream = buffed sourceBuffer
    stream.on 'error', done
    stream.on 'finish', ->
      assert.equal stream.combine().toString(), sourceContent.replace '{{key}}', 'value'
      done()

    command ['key=value'], stream, stream


  it 'with file path as arg', (done) ->

    stream = buffed sourceBuffer
    stream.on 'error', done
    stream.on 'finish', ->
      assert.equal stream.combine().toString(), sourceContent.replace '{{key}}', 'value'
      done()

    command [join 'test', 'helpers', 'input.json'], stream, stream


  it 'with NUC id available', (done) ->

    process.env.NUCID = 'kevasTest'

    stream = buffed sourceBuffer
    stream.on 'error', done
    stream.on 'finish', ->
      assert.equal stream.combine().toString(), sourceContent
      process.env.NUCID = null
      done()

    command [], stream, stream
