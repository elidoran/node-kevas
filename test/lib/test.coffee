assert   = require 'assert'
kevas    = require '../../lib'
strung   = require 'strung'
through  = require 'through2'
Path     = require 'fspath'

describe 'test kevas', ->

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
      values: key:'value'
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
      should:'should include the brace without the slash'
      output:['some \\{{ value']
      values: key:'good'
      result:'some {{ value'
    }
    {
      desc: 'with an escape slash before first opening brace which voids key'
      should:'should match input without key replacement'
      output:['some \\{{key}} value']
      values: key:'good'
      result:'some {{key}} value'
    }
    {
      desc: 'with two escape slashes before first opening brace which doesnt affect the key'
      output:['some \\\\{{key}} value']
      values: key:'good'
      result:'some \\\\good value'
    }

    # # # # # # # # # # # # # # # # # # # # # # # #
      # now redo escape test with split output  #
    # # # # # # # # # # # # # # # # # # # # # # # #
    {
      desc: 'with two escape slashes next to each other'
      should:'should include a single slash'
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
      desc: 'with an escape slash before first opening brace which voids key'
      should:'should match input without key replacement'
      output:['some \\', '{{key}} value']
      values: key:'good'
      result:'some {{key}} value'
    }
    {
      desc: 'with an escape slash before first opening brace which voids key'
      should:'should match input without key replacement'
      output:['some \\{', '{key}} value']
      values: key:'good'
      result:'some {{key}} value'
    }
    {
      desc: 'with two escape slashes before first opening brace which doesnt affect the key'
      output:['some \\\\', '{{key}} value']
      values: key:'good'
      result:'some \\\\good value'
    }

    {
      desc: 'with lots of output chunks'
      should:'should still escape a brace and match proper key'
      output:['some {', '{', 'key', '}', '} value']
      values: key:'good'
      result:'some good value'
    }

  ]
    do (test) ->
      describe test.desc, ->

        it test.should ? shouldReplaceKeyWithValue, (done) ->

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
  describe 'with json file input stream', ->

    it 'should convert unescaped keys to values', (done) ->

      dir = new Path 'test/helpers'

      file = dir.to 'kevas.json'

      expected = JSON.parse dir.to('expected.kevas.json').read()

      stream = kevas values:key:'good'

      output = strung()

      # when all writes are finished then verify the results
      output.on 'finish', (error) ->
        if error? then return done error
        result = JSON.parse output.string
        assert.deepEqual result, expected
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
