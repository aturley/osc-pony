use "collections"

interface OscData
  fun val toBytes(): Array[U8] val
  fun toTypeByte(): U8

class OscString is OscData
  let _data: String

  new val create(data: String) =>
    _data = data

  fun val _createPadArray(): Array[U8] =>
    Array[U8]().init(0, 4 - (_data.size() % 4))

  fun val toBytes(): Array[U8] val =>
    recover
      Array[U8]().concat(_data.values())
                 .concat(_createPadArray().values())
    end
                          
  fun toTypeByte(): U8 =>
    's'

class OscInt is OscData
  let _data: I32
  new val create(data: I32) =>
    _data = data
  fun val toBytes(): Array[U8 val] val =>
    recover [as U8 val: U8().from[I32]((_data >> 24) and 0xFF),
                        U8().from[I32]((_data >> 16) and 0xFF),
                        U8().from[I32]((_data >> 8) and 0xFF),
                        U8().from[I32](_data and 0xFF)] end
  fun toTypeByte(): U8 =>
    'i'

class OscFloat is OscData
  let _data: F32
  new val create(data: F32) =>
    _data = data
  fun val toBytes(): Array[U8 val] val =>
    let bits = _data.bits()
    recover [as U8 val: U8().from[U32]((bits  >> 24) and 0xFF),
                        U8().from[U32]((bits >> 16) and 0xFF),
                        U8().from[U32]((bits >> 8) and 0xFF),
                        U8().from[U32](bits and 0xFF)] end
  fun toTypeByte(): U8 =>
    'f'

type Argument is OscData
type Arguments is Array[Argument val]

class OscMessage
  let address: String val
  let arguments: Arguments val

  new val create(address': String val, arguments': Arguments val) =>
    address = address'
    arguments = arguments'

  fun _buildTypeString(): String ref =>
    var argumentsString = String().push(',')
    for arg in arguments.values() do
      argumentsString.push(arg.toTypeByte())
    end
    argumentsString

  fun val toBytes(): Array[U8 val] val =>
    recover
    var parts: Array[U8 val] = Array[U8 val].create()
    var oscAddress = OscString(address)
    var types = OscString(_buildTypeString().clone())

    parts.concat(oscAddress.toBytes().values())
    parts.concat(types.toBytes().values())
    for arg in arguments.values() do
      parts.concat(arg.toBytes().values())
    end

    parts
    end