(function() {
  var FORMAT_VERSION, NKSJsonDeserializer, _, _toHexByte, assert, events,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  assert = require('assert');

  events = require('events');

  _ = require('underscore');

  FORMAT_VERSION = 1;

  module.exports = function(data) {
    return new NKSJsonDeserializer(data);
  };

  NKSJsonDeserializer = (function(superClass) {
    extend(NKSJsonDeserializer, superClass);

    function NKSJsonDeserializer(data) {
      var version;
      this.buf = data;
      this.pos = 0;
      version = this._readUInt32LE();
      assert.ok(version === FORMAT_VERSION, "Unknown NKS format version. version:" + version);
    }

    NKSJsonDeserializer.prototype.deserialize = function() {
      var ret, start, type;
      type = this._readByte();
      assert.ok((type & 0xf0) === 0x80, "NKS object data must start with 0x8x. value:" + (_toHexByte(type)));
      start = this.pos;
      this.emit('start', null, this.pos);
      ret = this._readObject(type & 0x0f);
      this.emit('end', void 0, ret, this.buf.slice(start, this.pos));
      return ret;
    };

    NKSJsonDeserializer.prototype._readObject = function(length) {
      var i, j, key, ref, ret, start, value;
      ret = {};
      for (i = j = 0, ref = length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
        start = this.pos;
        key = this._readKey();
        this.emit('start', key, this.pos);
        value = this._readValue(key);
        ret[key] = value;
        this.emit('end', key, value, this.buf.slice(start, this.pos));
      }
      return ret;
    };

    NKSJsonDeserializer.prototype._readList = function(length) {
      var i, j, ref, results;
      results = [];
      for (i = j = 0, ref = length; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
        results.push(this._readValue());
      }
      return results;
    };

    NKSJsonDeserializer.prototype._readKey = function() {
      var type;
      type = this._readByte();
      switch (false) {
        case !(type < 0x0a0):
          return assert.ok(false, "Unsupported key type. type:" + (_toHexByte(type)));
        case !(type < 0x0c0):
          return this._readString(type & 0x1f);
        default:
          return assert.ok(false, "Unsupported key type. type:" + (_toHexByte(type)));
      }
    };

    NKSJsonDeserializer.prototype._readValue = function(key) {
      var type;
      type = this._readByte();
      switch (false) {
        case !(type < 0x80):
          return type;
        case !(type < 0x90):
          return this._readObject(type & 0x0f);
        case !(type < 0xa0):
          return this._readList(type & 0x0f);
        case !(type < 0xc0):
          return this._readString(type & 0x1f);
        case type !== 0xc0:
          return null;
        case type !== 0xc2:
          return false;
        case type !== 0xc3:
          return true;
        case type !== 0xcc:
          return this._readByte();
        case type !== 0xcd:
          return this._readUInt16BE();
        case type !== 0xce:
          return this._readString(4);
        case type !== 0xd9:
          return this._readString(this._readByte());
        case type !== 0xda:
          return this._readString(this._readUInt16BE());
        case type !== 0xdc:
          return this._readList(this._readUInt16BE());
        default:
          return assert.ok(false, "Unsupported value type. type:" + (_toHexByte(type)));
      }
    };

    NKSJsonDeserializer.prototype._readByte = function() {
      var ret;
      ret = this.buf[this.pos];
      this.pos += 1;
      return ret;
    };

    NKSJsonDeserializer.prototype._readUInt32LE = function() {
      var ret;
      ret = this.buf.readUInt32LE(this.pos);
      this.pos += 4;
      return ret;
    };

    NKSJsonDeserializer.prototype._readUInt16BE = function() {
      var ret;
      ret = this.buf.readUInt16BE(this.pos);
      this.pos += 2;
      return ret;
    };

    NKSJsonDeserializer.prototype._readString = function(length) {
      var ret;
      ret = this.buf.toString('utf8', this.pos, this.pos + length);
      this.pos += length;
      return ret;
    };

    return NKSJsonDeserializer;

  })(events);

  _toHexByte = function(value) {
    return "0x" + ("0" + (value.toString(16))).slice(-2);
  };

}).call(this);
