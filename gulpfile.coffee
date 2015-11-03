gulp        = require 'gulp'
coffeelint  = require 'gulp-coffeelint'
coffee      = require 'gulp-coffee'
del         = require 'del'
data        = require 'gulp-data'
watch       = require 'gulp-watch'
extract     = require 'gulp-riff-extractor'
exec        = require 'gulp-exec'
beautify    = require 'js-beautify'

$ =
  sparkDir: '/Library/Arturia/Spark/Third Party/Native Instruments/presets'
  minivDir: '/Library/Arturia/Mini V2/Third Party/Native Instruments/presets'
  velvetDir: "#{process.env.HOME}/Documents/Native Instruments/User Content/Velvet"
  serumDir: "#{process.env.HOME}/Documents/Native Instruments/User Content/Velvet"
  execOpts:
    continueOnError: false # default = false, true means don't emit error event
    pipeStdout: false      # default = false, true means stdout is written to file.contents
  execReportOpts:
    err: true              # default = true, false means don't write err
    stderr: true           # default = true, false means don't write stderr
    stdout: true           # default = true, false means don't write stdout


gulp.task 'coffeelint', ->
  gulp.src ['./*.coffee', './src/*.coffee']
    .pipe coffeelint './coffeelint.json'
    .pipe coffeelint.reporter()

gulp.task 'coffee', ['coffeelint'], ->
  gulp.src ['./src/*.coffee']
    .pipe coffee()
    .pipe gulp.dest './lib'

gulp.task 'default', [
  'coffeelint'
  'coffee'
  ]

gulp.task 'watch', ->
  gulp.watch './**/*.coffee', ['default']

gulp.task 'clean', (cb) ->
  del ['./**/*~', './test_out'], force: true, cb

#
# compare between original chunk and new chunk.
#
gulp.task 'test', ['test-spark', 'test-miniv', 'test-velvet', 'test-serum'],  ->
  gulp.src ['./test_out/**/*.orig']
    .pipe exec [
      'echo Compairing "<%= file.relative%>" : "<%= file.relative.slice(0, -4)%>new"'
      'cmp -b "<%= file.path%>" "<%= file.path.slice(0, -4)%>"new'
      ].join '&&'
    , $.execOpts
    .pipe exec.reporter $.execRepotOpts

#
# Arturia spark presets
#
gulp.task 'test-spark', ['default','clean'],  ->
  nks = require './'
  gulp.src ["#{$.sparkDir}/**/*.nksf"]
     # extract NISI/NACA/PLID chunks and save to test_out folder.
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['NISI', 'NICA', 'PLID']
      filename_template: "<%= basename %>.<%= id.trim().toLowerCase() %>.orig"
    .pipe gulp.dest './test_out'
    .pipe data (file) ->
      # desrilize to json object
      json = nks.deserializer file.contents
        .deserialize()
      # console.info beautify (JSON.stringify json), indent_size: 2

      # serialize to chunk again.
      serializer = nks.serializer json
      serializer.serialize()
      file.contents = serializer.buffer()
      # remove '.orig' extension
      file.path = file.path[..-6] + ".new"
    .pipe gulp.dest './test_out'

#
# Arturia miniv
#
gulp.task 'test-miniv', ['default','clean'],  ->
  nks = require './'
  gulp.src ["#{$.minivDir}/**/*.nksf"]
     # extract NISI/NACA/PLID chunks and save to test_out folder.
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['NISI', 'NICA', 'PLID']
      filename_template: "<%= basename %>.<%= id.trim().toLowerCase() %>.orig"
    .pipe gulp.dest './test_out'
    .pipe data (file) ->
      # desrilize to json object
      json = nks.deserializer file.contents
        .deserialize()
      # debug
      # console.info beautify (JSON.stringify json), indent_size: 2

      # serialize to chunk again.
      serializer = nks.serializer(json)
      serializer.serialize()
      file.contents = serializer.buffer()
      # remove '.orig' extension
      file.path = file.path[..-6] + ".new"
    .pipe gulp.dest './test_out'

#
# Air Music Technology Velvet
#
gulp.task 'test-velvet', ['default','clean'],  ->
  nks = require './'
  gulp.src ["#{$.velvetDir}/**/*.nksf"]
     # extract NISI/NACA/PLID chunks and save to test_out folder.
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['NISI', 'NICA', 'PLID']
      filename_template: "<%= basename %>.<%= id.trim().toLowerCase() %>.orig"
    .pipe gulp.dest './test_out'
    .pipe data (file) ->
      # desrilize to json object
      json = nks.deserializer file.contents
        .deserialize()
      # debug
      # console.info beautify (JSON.stringify json), indent_size: 2

      # serialize to chunk again.
      serializer = nks.serializer(json)
      serializer.serialize()
      file.contents = serializer.buffer()
      # remove '.orig' extension
      file.path = file.path[..-6] + ".new"
    .pipe gulp.dest './test_out'

#
# Xfer Records Serum
#
gulp.task 'test-serum', ['default','clean'],  ->
  nks = require './'
  gulp.src ["#{$.serumDir}/**/*.nksf"]
     # extract NISI/NACA/PLID chunks and save to test_out folder.
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['NISI', 'NICA', 'PLID']
      filename_template: "<%= basename %>.<%= id.trim().toLowerCase() %>.orig"
    .pipe gulp.dest './test_out'
    .pipe data (file) ->
      # desrilize to json object
      json = nks.deserializer file.contents
        .deserialize()
      # debug
      # console.info beautify (JSON.stringify json), indent_size: 2

      # serialize to chunk again.
      serializer = nks.serializer(json)
      serializer.serialize()
      file.contents = serializer.buffer()
      # remove '.orig' extension
      file.path = file.path[..-6] + ".new"
    .pipe gulp.dest './test_out'
