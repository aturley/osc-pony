use "collections"

interface OscData
  """
  This is the base class for all OSC message arguments.
  """

  fun val toBytes(): Array[U8] val
  """
  Convert the argument into the appropriate byte array.
  """

  fun val fromBytes(bytes: Array[U8] val): (OscData val, Array[U8] val) ?
  """
  Convert the bytes to an OscData object, and also returns the
  remainder of the bytes.
  """

  fun toTypeByte(): U8
  """
  Return the byte that represents the type of the argument for the
  type string.
  """

class OscString is OscData
  """
  This class represents an OSC string. Strings are made up of quartets
  of bytes and terminated with 1 or more '\0' characters. Therefore
  the size of an OSC string is always a multiple of 4.
  """
  
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

  fun val fromBytes(bytes: Array[U8] val): (OscData val, Array[U8] val) ? =>
    // find the end of the string data
    var lastByte: USize = 3
    while (lastByte < bytes.size()) and (bytes(lastByte) != '\0') do
      lastByte = lastByte + 4
    end
    if lastByte >= bytes.size() then
      error
    end

    // find the first null in the string
    var firstNull: USize = 0
    while bytes(firstNull) != '\0' do
      firstNull = firstNull + 1
    end

    // create the string
    var str: String val = recover
      let s = String()

      for i in Range[USize](0, firstNull) do
        s.push(bytes(i))
      end
      consume s
    end
    (recover OscString(str.clone()) end, recover bytes.slice(lastByte + 1) end)
                          
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

  fun val fromBytes(bytes: Array[U8] val): (OscData val, Array[U8] val) ? =>
    let num = I32.from[U32]((U32.from[U8](bytes(0)) << 24) +
                            (U32.from[U8](bytes(1)) << 16) +
                            (U32.from[U8](bytes(2)) << 8) +
                            U32.from[U8](bytes(3)))
    (recover OscInt(num) end, recover bytes.slice(4) end)

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

  fun val fromBytes(bytes: Array[U8] val): (OscData val, Array[U8] val) ? =>
    let num = F32.from_bits((U32.from[U8](bytes(0)) << 24) +
                            (U32.from[U8](bytes(1)) << 16) +
                            (U32.from[U8](bytes(2)) << 8) +
                            (U32.from[U8](bytes(3))))
    (recover OscFloat(num) end, recover bytes.slice(4) end)

  fun toTypeByte(): U8 =>
    'f'

  fun val value(): F32 val => _data

class OscBlob is OscData
  """
  This class represents an OSC blob. Blobs are made up of quartets
  of bytes and terminated with 1 or more '\0' characters. Therefore
  the size of an OSC blob is always a multiple of 4.
  """
  
  let _data: Array[U8] val

  new val create(data: Array[U8] val) =>
    _data = data

  fun val _createPadArray(): Array[U8] =>
    // pad to the next quartet of bytes if necessary
    let mapping = [as USize: 0, 3, 2, 1]
    let pad_size = try mapping(_data.size() % 4) else 0 end
    Array[U8]().init(0, pad_size)

  fun val toBytes(): Array[U8] val =>
    let size: U32 = U32.from[USize](_data.size())
    recover
      Array[U8]().push(U8.from[U32]((size >> 24) and 0xFF))
                 .push(U8.from[U32]((size >> 16) and 0xFF))
                 .push(U8.from[U32]((size >> 8) and 0xFF))
                 .push(U8.from[U32]((size and 0xFF)))
                 .concat(_data.values())
                 .concat(_createPadArray().values())
    end

  fun val fromBytes(bytes: Array[U8] val): (OscData val, Array[U8] val) ? =>
    let size = USize.from[U32]((U32.from[U8](bytes(0)) << 24) +
                              (U32.from[U8](bytes(1)) << 16) +
                              (U32.from[U8](bytes(2)) << 8) +
                              U32.from[U8](bytes(3)))

    let data: Array[U8] val = recover
      let d = Array[U8](size)
      bytes.copy_to(d, 4, 0, size)
      consume d
    end

    // Data comes in quartets of bytes, find the quartet size
    let quartet_size = (((size - 1) / 4) + 1) * 4

    (OscBlob(data), recover bytes.slice(4 + quartet_size) end)
                          
  fun toTypeByte(): U8 =>
    'b'

  fun val value(): Array[U8] val => _data

class OscTrue is OscData
  let _data: Bool
  new val create() =>
    _data = true

  fun val toBytes(): Array[U8 val] val =>
    recover Array[U8](0) end

  fun val fromBytes(bytes: Array[U8] val): (OscData val, Array[U8] val) =>
    (OscTrue, recover bytes.slice(0) end)

  fun toTypeByte(): U8 =>
    'T'

  fun val value(): Bool => _data

class OscFalse is OscData
  let _data: Bool
  new val create() =>
    _data = true

  fun val toBytes(): Array[U8 val] val =>
    recover Array[U8](0) end

  fun val fromBytes(bytes: Array[U8] val): (OscData val, Array[U8] val) =>
    (OscFalse, recover bytes.slice(0) end)

  fun toTypeByte(): U8 =>
    'F'

  fun val value(): Bool => _data

class OscTimestamp is OscData
  let _data: U64

  new val create(data: U64) =>
    _data = data

  fun val toBytes(): Array[U8] val =>
    recover
      Array[U8]().push(U8.from[U64]((_data >> 56) and 0xFF))
                 .push(U8.from[U64]((_data >> 48) and 0xFF))
                 .push(U8.from[U64]((_data >> 40) and 0xFF))
                 .push(U8.from[U64]((_data >> 32) and 0xFF))
                 .push(U8.from[U64]((_data >> 24) and 0xFF))
                 .push(U8.from[U64]((_data >> 16) and 0xFF))
                 .push(U8.from[U64]((_data >> 8) and 0xFF))
                 .push(U8.from[U64]((_data and 0xFF)))
    end

  fun val fromBytes(bytes: Array[U8] val): (OscData val, Array[U8] val) ? =>
    let data = ((U64.from[U8](bytes(0)) << 56) +
                (U64.from[U8](bytes(1)) << 48) +
                (U64.from[U8](bytes(2)) << 40) +
                (U64.from[U8](bytes(3)) << 32) +
                (U64.from[U8](bytes(4)) << 24) +
                (U64.from[U8](bytes(5)) << 16) +
                (U64.from[U8](bytes(6)) << 8) +
                U64.from[U8](bytes(7)))

    (OscTimestamp(data), recover bytes.slice(8) end)
                          
  fun toTypeByte(): U8 =>
    't'

  fun val value(): U64 => _data

class OscNull is OscData
  let _data: None
  new val create() =>
    _data = None

  fun val toBytes(): Array[U8 val] val =>
    recover Array[U8](0) end

  fun val fromBytes(bytes: Array[U8] val): (OscData val, Array[U8] val) =>
    (OscNull, recover bytes.slice(0) end)

  fun toTypeByte(): U8 =>
    'N'

  fun val value(): None => _data

class OscImpulse is OscData
  let _data: None
  new val create() =>
    _data = None

  fun val toBytes(): Array[U8 val] val =>
    recover Array[U8](0) end

  fun val fromBytes(bytes: Array[U8] val): (OscData val, Array[U8] val) =>
    (OscImpulse, recover bytes.slice(0) end)

  fun toTypeByte(): U8 =>
    'I'

  fun val value(): None => _data

type Argument is OscData
type Arguments is Array[Argument val]

class OscMessage
  """
  This class represents OSC messages, as defined by the OSC standard
  (http://opensoundcontrol.org/). The byte reprsentation of an OSC
  messages consist of an address string, a type string, and zero or
  more arguments. Because the type string can be derived from the
  types of the arguments, the user of this class is not responsible
  for providing a type string when creating an `OscMessage`.
  """

  let address: String val
  let arguments: Arguments val

  new val create(address': String val, arguments': Arguments val) =>
  """
  Create an OscMessage from an address string and one or more OscData
  arguments.
  """
    address = address'
    arguments = arguments'

  fun _buildTypeString(): String ref =>
    var argumentsString = String().push(',')
    for arg in arguments.values() do
      argumentsString.push(arg.toTypeByte())
    end
    argumentsString

  fun val toBytes(): Array[U8 val] val =>
  """
  Generate a byte array that represents an OSC message as defined by
  the OSC standard.
  """
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


