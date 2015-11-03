assert = require 'assert'
_      = require 'underscore'

FORMAT_VERSION = 1

# function([length])
#
# - json    json object
# - return  instance of serializer
module.exports = (json) ->
  new NKSJsonSerializer json


class NKSJsonSerializer
  # new NISIChunkBuilder(length)
  #
  # - length    num of meta items.
  constructor: (json) ->
    @json = json
    # version 4byte + num of meta items 1 byte
    @buf = new Buffer 4
    # version 1
    @buf.writeUInt32LE FORMAT_VERSION, 0

  serialize: ->
    @_pushValue @json
    @
  # _pushValue(value)
  #
  # - size    num of meta items. *optional
  _pushValue: (value, key) ->
    switch
      # null
      when _.isNull value
        @_pushByte 0xc0
        
      # list
      when _.isArray value
        switch

          # list length = 0
          when value.length is 0
            @_pushByte 0x90

          # list length < 16
          when value.length < 16
            @_pushByte (0x90 + value.length)
            @_pushValue v for v in value
            @

          # list length >= 16
          else
            @_pushByte 0xdc
            @_pushUInt16BE  value.length
            @_pushValue v for v in value
            @
            
      # String
      when _.isString value
        s = new Buffer value, 'utf8'
        
        switch
          # empty string ""
          when s.length is 0
            @_pushByte 0xa0
          
          when key is "VST.magic"
            assert.ok (s.length is 4), "Vst.magic must be 4 characters value. value:#{value}"
            @_pushByte 0xce
            @_push s
          
          # Arturia using 0xda for UUID ?
          when key is "UUID" and s.length >= 32
            @_pushByte 0xda
            @_pushUInt16BE  s.length
            @_push s
          
          # string length =  1-31
          when s.length < 32
            @_pushByte (0xa0 + s.length)
            @_push s
          
          # string length =  32 - 127 or (255)
          when s.length < 256
            @_pushByteArray [0xd9, s.length]
            @_push s

          # string length >= 128 or (256)
          when s.length < 0x10000
            @_pushByte 0xda
            @_pushUInt16BE s.length
            @_push s
          else
            assert.ok false, "String length must be less than 16bit."

      # Number
      when _.isNumber value
        switch
          
          # 7bit int 0x00 - 0x7f
          when value < 128
            @_pushByte value

          # 8 bit int
          when value < 0x100
            @_pushByte 0xcc
            @_pushByte value

          # 16 bit int
          when value < 0x10000
            @_pushByte 0xcd
            @_pushUInt16BE value
          else
            assert.ok false, "Number value must be less than 16bit."
            
      # Boolean
      when _.isBoolean value
        @_pushByte if value then 0xc3 else 0xc2
        
      # Object
      when _.isObject value
        length = (_.keys value).length
        assert.ok (length < 16), "Number of object properties must be less than 16."
        @_pushByte (0x80 + length)
        for key, v of value
          assert.ok (_.isString key),  "Property key must be String. key:#{key}"
          assert.ok (key.length > 0), "Property key lenth must be greater than 0."
          @_pushValue key
          @_pushValue v, key

      # Unknown type
      else
        assert.ok false, "Unsupported value type. type:#{typeof Value}"



  # buffer()
  #
  # - return current buffer of NISI chunk data.
  buffer: ->
    @buf

  # buffer()
  #
  # - return current size of NISI chunk data.
  tell: ->
    @buf.length

  # push(buffer, [start], [end])
  #
  # - buffer buffer object to push
  # - start  nuNumber, optionalm Default:0
  # - start  start offset to slice, optional, Default:0
  # - end    end offset to slice, optional, Default: buffer.length
  # - return this instance
  _push: (buf, start, end) ->
    b = buf
    if _.isNumber start
      if _.isNumber end
        b = buf.slice start, end
      else
        b = buf.slice start
    @buf = Buffer.concat [@buf, b]
    @

  _pushByte: (value) ->
    @_push new Buffer([value])
    @
    
  _pushUInt16BE: (value) ->
    b = new Buffer 2
    b.writeUInt16BE value, 0
    @_push b
    @

  _pushByteArray: (value) ->
    @_push new Buffer(value)
    @

