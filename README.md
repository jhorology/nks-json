## nks-json

Serializing and Deserializing between JSON and NKS preset chunk.

## Installation
```
  npm install nks-json
```

## Usage

converting chunk to json file.
```coffeescript

data     = require 'gulp-data'
extract  = require 'gulp-riff-extractor'
beautify = require 'js-beautify'
nks      = require 'nks-json'

gulp.task 'test-spark', ['default','clean'],  ->
  gulp.src [".../Serum/**/*.nksf"]
     # extract NISI/NACA/PLID chunks
    .pipe extract
      form_type: 'NIKS'
      chunk_ids: ['NISI', 'NICA', 'PLID']
    .pipe data (file) ->
      # desrilize to json object
      json = nks.deserializer file.contents
        .deserialize()
      file.contents = new Buffer (beautify (JSON.stringify json), indent_size: 2)
      file.path += '.json'
    .pipe gulp.dest 'dist'
```

converting json to chunk file.
```coffeescript

data     = require 'gulp-data'
extract  = require 'gulp-riff-extractor'
beautify = require 'js-beautify'
nks      = require 'nks-json'

gulp.task 'test-spark', ['default','clean'],  ->
  gulp.src [
    '.../src/**/*.nisi.json'
    '.../src/**/*.nica.json'
    '.../src/**/*.plid.json'
    ]
    .pipe data (file) ->
      json = require file.path
      serializer = nks.serializer json
      serializer.serialize()
      file.contents = serializer.buffer()
      # remove '.json' extension
      file.path = file.path[..-5]
    .pipe gulp.dest 'dist'
```

## TODO
- asynchronous operation
- streaming
