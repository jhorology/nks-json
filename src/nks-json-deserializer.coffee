assert = require 'assert'
events = require 'events'
_      = require 'underscore'

# NISI chunk format version
FORMAT_VERSION = 1

# function(data)
#
# - data   buffer of chunk data content.
# - return instance of deserializer
module.exports = (data) ->
  new NKSJsonDeserializer data

# class NKS Json Deserializer
#
# events:
#   start on('start', function(key, pos) {
#     // - key      key of node. null = root node
#     // - pos      buffer position
#   });
#
#   start on('end', function(key, value, buffer, pos) {
#      // - key     key of node. null = root node
#      // - value   value of node
#      // - buffer  buffer contained key/value pair
#      // - pos     buffer position
#   });
#
class NKSJsonDeserializer extends events
  # new NKSDeserializer(data)
  #
  # - data   buffer of chunk data content.
  constructor: (data) ->
    # chunk id 4byte + size 4byte
    @buf = data
    @pos = 0
    version = @_readUInt32LE()
    assert.ok (version is FORMAT_VERSION), "Unknown NKS format version. version:#{version}"

  # deserialize()
  #
  # - return   JSON object
  deserialize: ->
    type = @_readByte()
    assert.ok ((type & 0xf0) is 0x80), "NKS object data must start with 0x8x. value:#{_toHexByte type}"
    start = @pos
    @emit 'start', null, @pos
    ret = @_readObject (type & 0x0f)
    @emit 'end', undefined, ret, @buf.slice start, @pos
    ret
    
  _readObject: (length) ->
    ret = {}
    for i in [0...length]
      start = @pos
      key = @_readKey()
      @emit 'start', key, @pos
      value = @_readValue key
      ret[key] = value
      @emit 'end', key, value, @buf.slice start, @pos
    ret
    
  _readList: (length) ->
    @_readValue() for i in [0...length]
    
  _readKey: ->
    type = @_readByte()
    switch
      # error
      when type < 0x0a0
        assert.ok false, "Unsupported key type. type:#{_toHexByte type}"
      # 0xa0-0xbf string length < 32
      when type < 0x0c0
        @_readString (type & 0x1f)
      else
        assert.ok false, "Unsupported key type. type:#{_toHexByte type}"

  _readValue: (key) ->
    type = @_readByte()
    switch
      # 0x00-0x7f 7bit int
      when type < 0x80 then type
      # 0x80-0x8f object (key/value pairs)
      when type < 0x90 then @_readObject (type & 0x0f)
      # 0x90-0x9f list values
      when type < 0xa0 then @_readList (type & 0x0f)
      # 0xa0-0xbf string length < 32
      when type < 0xc0 then @_readString (type & 0x1f)
      # null
      when type is 0xc0 then null
      # 0xc2  bool false
      when type is 0xc2 then off
      # 0xc2  bool true
      when type is 0xc3 then on
      # 8bit int
      when type is 0xcc then @_readByte()
      # 16bit int
      when type is 0xcd then @_readUInt16BE()
      # 4 character id
      when type is 0xce then @_readString 4
      # string < 256
      when type is 0xd9 then @_readString @_readByte()
      # string >= 256 *maybe
      when type is 0xda then @_readString @_readUInt16BE()
      # list >= 16 *maybe
      when type is 0xdc then @_readList @_readUInt16BE()
      else
        assert.ok false, "Unsupported value type. type:#{_toHexByte type}"
    
  _readByte: ->
    ret = @buf[@pos]
    @pos += 1
    ret

  _readUInt32LE: ->
    ret = @buf.readUInt32LE @pos
    @pos += 4
    ret

  _readUInt16BE: ->
    ret = @buf.readUInt16BE @pos
    @pos += 2
    ret

  _readString: (length) ->
    ret = @buf.toString 'utf8', @pos, (@pos + length)
    @pos += length
    ret

# utils
# -------------------

#  convert byte to hex string
_toHexByte = (value) ->
  "0x" + "0#{value.toString 16}"[-2..]
