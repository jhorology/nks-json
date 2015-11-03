(function() {
  var FORMAT_VERSION, NKSJsonSerializer, _, assert;

  assert = require('assert');

  _ = require('underscore');

  FORMAT_VERSION = 1;

  module.exports = function(json) {
    return new NKSJsonSerializer(json);
  };

  NKSJsonSerializer = (function() {
    function NKSJsonSerializer(json) {
      this.json = json;
      this.buf = new Buffer(4);
      this.buf.writeUInt32LE(FORMAT_VERSION, 0);
    }

    NKSJsonSerializer.prototype.serialize = function() {
      this._pushValue(this.json);
      return this;
    };

    NKSJsonSerializer.prototype._pushValue = function(value, key) {
      var i, j, len, len1, length, results, s, v;
      switch (false) {
        case !_.isNull(value):
          return this._pushByte(0xc0);
        case !_.isArray(value):
          switch (false) {
            case value.length !== 0:
              return this._pushByte(0x90);
            case !(value.length < 16):
              this._pushByte(0x90 + value.length);
              for (i = 0, len = value.length; i < len; i++) {
                v = value[i];
                this._pushValue(v);
              }
              return this;
            default:
              this._pushByte(0xdc);
              this._pushUInt16BE(value.length);
              for (j = 0, len1 = value.length; j < len1; j++) {
                v = value[j];
                this._pushValue(v);
              }
              return this;
          }
          break;
        case !_.isString(value):
          s = new Buffer(value, 'utf8');
          switch (false) {
            case s.length !== 0:
              return this._pushByte(0xa0);
            case key !== "VST.magic":
              assert.ok(s.length === 4, "Vst.magic must be 4 characters value. value:" + value);
              this._pushByte(0xce);
              return this._push(s);
            case !(key === "UUID" && s.length >= 32):
              this._pushByte(0xda);
              this._pushUInt16BE(s.length);
              return this._push(s);
            case !(s.length < 32):
              this._pushByte(0xa0 + s.length);
              return this._push(s);
            case !(s.length < 256):
              this._pushByteArray([0xd9, s.length]);
              return this._push(s);
            case !(s.length < 0x10000):
              this._pushByte(0xda);
              this._pushUInt16BE(s.length);
              return this._push(s);
            default:
              return assert.ok(false, "String length must be less than 16bit.");
          }
          break;
        case !_.isNumber(value):
          switch (false) {
            case !(value < 128):
              return this._pushByte(value);
            case !(value < 0x100):
              this._pushByte(0xcc);
              return this._pushByte(value);
            case !(value < 0x10000):
              this._pushByte(0xcd);
              return this._pushUInt16BE(value);
            default:
              return assert.ok(false, "Number value must be less than 16bit.");
          }
          break;
        case !_.isBoolean(value):
          return this._pushByte(value ? 0xc3 : 0xc2);
        case !_.isObject(value):
          length = (_.keys(value)).length;
          assert.ok(length < 16, "Number of object properties must be less than 16.");
          this._pushByte(0x80 + length);
          results = [];
          for (key in value) {
            v = value[key];
            assert.ok(_.isString(key), "Property key must be String. key:" + key);
            assert.ok(key.length > 0, "Property key lenth must be greater than 0.");
            this._pushValue(key);
            results.push(this._pushValue(v, key));
          }
          return results;
          break;
        default:
          return assert.ok(false, "Unsupported value type. type:" + (typeof Value));
      }
    };

    NKSJsonSerializer.prototype.buffer = function() {
      return this.buf;
    };

    NKSJsonSerializer.prototype.tell = function() {
      return this.buf.length;
    };

    NKSJsonSerializer.prototype._push = function(buf, start, end) {
      var b;
      b = buf;
      if (_.isNumber(start)) {
        if (_.isNumber(end)) {
          b = buf.slice(start, end);
        } else {
          b = buf.slice(start);
        }
      }
      this.buf = Buffer.concat([this.buf, b]);
      return this;
    };

    NKSJsonSerializer.prototype._pushByte = function(value) {
      this._push(new Buffer([value]));
      return this;
    };

    NKSJsonSerializer.prototype._pushUInt16BE = function(value) {
      var b;
      b = new Buffer(2);
      b.writeUInt16BE(value, 0);
      this._push(b);
      return this;
    };

    NKSJsonSerializer.prototype._pushByteArray = function(value) {
      this._push(new Buffer(value));
      return this;
    };

    return NKSJsonSerializer;

  })();

}).call(this);
