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

  fun val value(): String val => _data

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

  fun val value(): I32 => _data

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

  fun val value(): F32 val => _data

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


  new val fromBytes(input: Array[U8] val) ? =>
    let addressLimits = StringLimits.fromBytes(input, 0)
    let typesLimits = StringLimits.fromBytes(input, addressLimits.e() + 1)
    let argsCount = typesLimits.sz() - 1

    var last: (StringLimits val | FloatLimits val | IntLimits val) = typesLimits

    var oscArgs: Array[OscData val] trn = recover Array[OscData val] end

    for i in Range[I32](1, typesLimits.sz()) do
      last = match input(USize.from[I32](typesLimits.s() + i))
        | 's' => StringLimits.fromBytes(input, last.e() + 1)
        | 'f' => FloatLimits.fromBytes(input, last.e() + 1)
        | 'i' => IntLimits.fromBytes(input, last.e() + 1)
        else
          error
        end

      match last
        | let str: StringLimits val => oscArgs.push(OscString(str.extractFromBytes(input)))
        | let fl: FloatLimits val => oscArgs.push(OscFloat(fl.extractFromBytes(input)))
        | let int: IntLimits val => oscArgs.push(OscInt(int.extractFromBytes(input)))
      end
    end

    address = addressLimits.extractFromBytes(input)
    arguments = consume oscArgs