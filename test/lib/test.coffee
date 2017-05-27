assert   = require 'assert'
kevas    = require '../../lib'
strung   = require 'strung'
through  = require 'through2'
Path     = require 'fspath'

describe 'test kevas', ->

  it 'should use a noop function when not given values', ->

    string = 'test {{noop}} function'
    transform = kevas()

    calledData = []
    transform.on 'data', (data) -> calledData.push data
    transform.end string

    assert calledData.length > 0
    for each, index in calledData
      assert Buffer.isBuffer(each), 'index ' + index + ' isnt a buffer'
    assert.equal Buffer.concat(calledData).toString(), string


  it 'should use a values function when given', ->

    string = 'test {{value}} function'
    transform = kevas values: (key) -> if key is 'value' then 'VALUE'

    calledData = []
    transform.on 'data', (data) -> calledData.push data
    transform.end string

    assert calledData.length > 0
    for each, index in calledData
      assert Buffer.isBuffer(each), 'index ' + index + ' isnt a buffer'
    assert.equal Buffer.concat(calledData).toString(), 'test VALUE function'


  it 'should use a noop function when given an invalid values type', ->

    string = 'test {{noop}} function'
    transform = kevas values: 123

    calledData = []
    transform.on 'data', (data) -> calledData.push data
    transform.end string

    assert calledData.length > 0
    for each, index in calledData
      assert Buffer.isBuffer(each), 'index ' + index + ' isnt a buffer'
    assert.equal Buffer.concat(calledData).toString(), string


  it 'should leave key wrapped with braces when there\'s no value for the key', ->

    string = 'test {{unknown}} function'
    transform = kevas values: {}

    calledData = []
    transform.on 'data', (data) -> calledData.push data
    transform.end string

    assert calledData.length > 0
    for each, index in calledData
      assert Buffer.isBuffer(each), 'index ' + index + ' isnt a buffer'
    assert.equal Buffer.concat(calledData).toString(), string


  shouldReplaceKeyWithValue = 'should replace the key with its value'
  for test in [
    {
      desc: 'with static string'
      should: 'should output the string as-is'
      output: ['some static test string']
      result: 'some static test string'
    }
    {
      desc: 'with multiple static strings'
      should: 'should output the combined string as-is'
      output: [ 'some static test string', '\nanother string on a new line',
                ' - string added to tail of second line', '\nthird line on a new line']
      result: 'some static test string\nanother string on a new line
               - string added to tail of second line\nthird line on a new line'
    }
    {
      desc: 'with a single key alone in string'
      output:['{{key}}']
      values: key:'value'
      result:'value'
    }
    {
      desc: 'with a single key surrouned by space'
      output:['{{ key }}']
      values: ' key ':'value'
      result:'value'
    }
    {
      desc: 'with a single key surrounded by text'
      output:['some {{key}} value']
      values: key:'good'
      result:'some good value'
    }
    {
      desc: 'with a single key chunk split after first open brace'
      output:['some {', '{key}} value']
      values: key:'good'
      result:'some good value'
    }
    {
      desc: 'with a single key chunk split after second open brace'
      output:['some {{', 'key}} value']
      values: key:'good'
      result:'some good value'
    }
    {
      desc: 'with a single key chunk split in its middle'
      output:['some {{k', 'ey}} value']
      values: key:'good'
      result:'some good value'
    }
    {
      desc: 'with a single key chunk split before the first closing brace'
      output:['some {{key', '}} value']
      values: key:'good'
      result:'some good value'
    }
    {
      desc: 'with a single key chunk split before the second closing brace'
      output:['some {{key}', '} value']
      values: key:'good'
      result:'some good value'
    }
    {
      desc: 'with one escape slashes next to each other'
      should:'should include a single slash'
      output:['some \\ value']
      values: key:'good'
      result:'some \\ value'
    }
    {
      desc: 'with two escape slashes next to each other'
      should:'should include a single slash'
      output:['some \\\\ value']
      values: key:'good'
      result:'some \\\\ value'
    }
    {
      desc: 'with escaped opening brace'
      should:'should include the braces without the slash'
      output:['some \\{{ value']
      values: key:'good'
      result:'some {{ value'
    }
    {
      desc: 'with escaped closing brace'
      should:'should include the brace without the slash'
      output:['some {{key\\}}} value']
      values: 'key}':'good'
      result:'some good value'
    }
    {
      desc: 'with an escape slash before first opening brace which voids key'
      should:'should match input without key replacement'
      output:['some \\{{key}} value']
      values: key:'good'
      result:'some {{key}} value'
    }
    {
      desc: 'with escaped slash before first opening brace which doesnt affect the key'
      output:['some \\\\{{key}} value']
      values: key:'good'
      result:'some \\good value'
    }
    {
      desc: 'brace found at >1 w two slashes before it'
      output:[' \\\\{']
      values: key:'good'
      result:' \\\\{'
    }
    {
      desc: 'brace found at 1 w/out slash before it'
      output:[' {']
      values: key:'good'
      result:' {'
    }
    {
      desc: 'brace found at 1 with slash before it'
      output:['\\{']
      values: key:'good'
      result:'\\{'
    }
    {
      desc: 'slash found last w/out slash before it'
      output:[' \\']
      values: key:'good'
      result:' \\'
    }
    {
      desc: 'dangling key gets flushed at end()'
      output:['some dangling {{key']
      values: key:'good'
      result:'some dangling {{key'
    }

    # # # # # # # # # # # # # # # # # # # # # # # #
    #   now redo escape test with split output    #
    # # # # # # # # # # # # # # # # # # # # # # # #
    {
      desc: 'with two escape slashes next to each other without a pair after it'
      should:'should remain two slashes'
      output:['some \\', '\\ value']
      values: key:'good'
      result:'some \\\\ value'
    }
    {
      desc: 'with escaped opening brace'
      should:'should include the brace without the slash'
      output:['some \\', '{{ value']
      values: key:'good'
      result:'some {{ value'
    }
    {
      desc: 'with an escape slash before first opening brace which voids key (1)'
      should:'should match input without key replacement'
      output:['some \\', '{{key}} value']
      values: key:'good'
      result:'some {{key}} value'
    }
    {
      desc: 'with an escape slash before first opening brace which voids key (2)'
      should:'should match input without key replacement'
      output:['some \\{', '{key}} value']
      values: key:'good'
      result:'some {{key}} value'
    }
    {
      desc: 'with two escape slashes before first opening brace which doesnt affect the key (1)'
      output:['some \\\\', '{{key}} value']
      values: key:'good'
      result:'some \\\\good value'
    }
    {
      desc: 'with two escape slashes before first opening brace which doesnt affect the key (2)'
      output:['some \\', '\\{{key}} value']
      values: key:'good'
      result:'some \\good value'
    }
    {
      desc: 'with two escape slashes before first closing brace which becomes part of the key'
      output:['some {{ke\\', '\\y}} value']
      values: 'ke\\\\y':'good'
      result:'some good value'
    }
    {
      desc: 'with escape slash at start of second chunk escaping opening braces'
      output:['some ', '\\{{key}} value']
      values: key:'good'
      result:'some {{key}} value'
    }
    {
      desc: 'with short chunk, previous slash, and slash at start of second chunk'
      should:'should escape slash and still match key'
      output:['some \\', '\\{', '{key}} value']
      values: key:'good'
      result:'some \\good value'
    }
    {
      desc: 'with lots of output chunks'
      should:'should still escape a brace and match proper key'
      output:['some {', '{', 'key', '}', '} value']
      values: key:'good'
      result:'some good value'
    }
    {
      desc: 'dangling key gets flushed at end()'
      output:['some dangling {', '{k', 'ey']
      values: key:'good'
      result:'some dangling {{key'
    }
  ]
    do (test) ->
      it test.desc + ' ' + (test.should ? shouldReplaceKeyWithValue), (done) ->

        # create a through stream as a pass-through to pipe to our stream
        input = through()

        # create our stream with values provided by the test
        stream = kevas values:test.values

        # create a sink stream to collect all it receives into a string
        output = strung()

        # when all writes are finished then verify the results
        output.on 'finish', ->
          assert.equal output?.string, test.result
          done() # tell Mocha the test is done

        # send any errors to Mocha's callback
        input.on  'error', done
        stream.on 'error', done
        output.on 'error', done

        # pipe our test input to our stream and then to our output collector.
        input.pipe(stream).pipe(output)

        # asynchronously write chunks to the input stream
        # allow for pause/resume with on-drain.
        index = 0
        ready = true
        writeout = (error) ->
          if error? then return done error
          unless ready then return input.once('drain', writeout)
          if index < test.output.length
            ready = input.write test.output[index], 'utf8', writeout
            index++
          else
            input.end()

        writeout()

# TODO: set of tests using a file stream as input (use filed? or paths?)
  it 'with json file input stream should convert unescaped keys to values', (done) ->

    dir = new Path 'test/helpers'

    file = dir.to 'kevas.json'

    expected = dir.to('expected.kevas.json').read encoding:'utf8'

    stream = kevas values:key:'good'

    output = strung()

    # when all writes are finished then verify the results
    output.on 'finish', (error) ->
      if error? then return done error
      result = output.string
      assert.equal result, expected
      done() # tell Mocha the test is done

    # send any errors to Mocha's callback
    stream.on 'error', done
    output.on 'error', done

    options = # send errors to `done`
      reader:
        events:
          'error': done
      writer:
        events:
          'error': done

    # pipe our test input to our stream and then to our output collector.
    file.pipe(stream, options).pipe(output)



# TODO: set of tests using a file stream as output (use filed? or paths?)
