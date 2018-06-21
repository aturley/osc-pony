"""
# OSCPony Package

Provides a set of classes for decoding a byte array into an OSC
message and encoding an OSC message as a byte array. Currently
supports all OSC 2.0 datatypes, but does not support OSC bundles.

For more information about Open Sound Control, please see
http://opensoundcontrol.org/.
"""

use "collections"

interface OSCData
  """
  This is the base class for all OSC message arguments.
  """

  fun val to_bytes(): Array[U8] val
  """
  Convert the argument into the appropriate byte array.
  """

  fun val from_bytes(bytes: Array[U8] val): (OSCData val, Array[U8] val) ?
  """
  Convert the bytes to an OSCData object, and also returns the
  remainder of the bytes.
  """

  fun to_type_byte(): U8
  """
  Return the byte that represents the type of the argument for the
  type string.
  """

class OSCString is OSCData
  """
  This class represents an OSC string. Strings are made up of quartets
  of bytes and terminated with 1 or more '\0' characters. Therefore
  the size of an OSC string is always a multiple of 4.
  """

  let _data: String

  new val create(data: String) =>
    _data = data

  fun val _create_pad_array(): Array[U8] =>
    Array[U8]().init(0, 4 - (_data.size() % 4))

  fun val to_bytes(): Array[U8] val =>
    recover
      Array[U8]
        .>concat(_data.values())
        .>concat(_create_pad_array().values())
    end

  fun val from_bytes(bytes: Array[U8] val): (OSCData val, Array[U8] val) ? =>
    // find the end of the string data
    var last_byte: USize = 3
    while (last_byte < bytes.size()) and (bytes(last_byte)? != '\0') do
      last_byte = last_byte + 4
    end
    if last_byte >= bytes.size() then
      error
    end

    // find the first null in the string
    var first_null: USize = 0
    while bytes(first_null)? != '\0' do
      first_null = first_null + 1
    end

    // create the string
    var str: String val = recover
      let s = String(first_null)

      for i in Range[USize](0, first_null) do
        s.push(bytes(i)?)
      end
      consume s
    end
    (recover OSCString(str) end, recover bytes.slice(last_byte + 1) end)

  fun to_type_byte(): U8 =>
    's'

  fun val value(): String val => _data

class OSCInt is OSCData
  let _data: I32
  new val create(data: I32) =>
    _data = data

  fun val to_bytes(): Array[U8 val] val =>
    recover [as U8 val: U8.from[I32]((_data >> 24) and 0xFF)
                        U8.from[I32]((_data >> 16) and 0xFF)
                        U8.from[I32]((_data >> 8) and 0xFF)
                        U8.from[I32](_data and 0xFF)] end

  fun val from_bytes(bytes: Array[U8] val): (OSCData val, Array[U8] val) ? =>
    let num = I32.from[U32]((U32.from[U8](bytes(0)?) << 24) +
                            (U32.from[U8](bytes(1)?) << 16) +
                            (U32.from[U8](bytes(2)?) << 8) +
                            U32.from[U8](bytes(3)?))
    (recover OSCInt(num) end, recover bytes.slice(4) end)

  fun to_type_byte(): U8 =>
    'i'

  fun val value(): I32 => _data

class OSCFloat is OSCData
  let _data: F32
  new val create(data: F32) =>
    _data = data

  fun val to_bytes(): Array[U8 val] val =>
    let bits = _data.bits()
    recover [as U8 val: U8.from[U32]((bits  >> 24) and 0xFF)
                        U8.from[U32]((bits >> 16) and 0xFF)
                        U8.from[U32]((bits >> 8) and 0xFF)
                        U8.from[U32](bits and 0xFF)] end

  fun val from_bytes(bytes: Array[U8] val): (OSCData val, Array[U8] val) ? =>
    let num = F32.from_bits((U32.from[U8](bytes(0)?) << 24) +
                            (U32.from[U8](bytes(1)?) << 16) +
                            (U32.from[U8](bytes(2)?) << 8) +
                            (U32.from[U8](bytes(3)?)))
    (recover OSCFloat(num) end, recover bytes.slice(4) end)

  fun to_type_byte(): U8 =>
    'f'

  fun val value(): F32 val => _data

class OSCBlob is OSCData
  """
  This class represents an OSC blob. Blobs are made up of quartets
  of bytes and terminated with 1 or more '\0' characters. Therefore
  the size of an OSC blob is always a multiple of 4.
  """

  let _data: Array[U8] val

  new val create(data: Array[U8] val) =>
    _data = data

  fun val _create_pad_array(): Array[U8] =>
    // pad to the next quartet of bytes if necessary
    let mapping = [as USize: 0; 3; 2; 1]
    let pad_size = try mapping(_data.size() % 4)? else 0 end
    Array[U8]().init(0, pad_size)

  fun val to_bytes(): Array[U8] val =>
    let size: U32 = U32.from[USize](_data.size())
    recover
      Array[U8]().>push(U8.from[U32]((size >> 24) and 0xFF))
                 .>push(U8.from[U32]((size >> 16) and 0xFF))
                 .>push(U8.from[U32]((size >> 8) and 0xFF))
                 .>push(U8.from[U32]((size and 0xFF)))
                 .>concat(_data.values())
                 .>concat(_create_pad_array().values())
    end

  fun val from_bytes(bytes: Array[U8] val): (OSCData val, Array[U8] val) ? =>
    let size = USize.from[U32]((U32.from[U8](bytes(0)?) << 24) +
                              (U32.from[U8](bytes(1)?) << 16) +
                              (U32.from[U8](bytes(2)?) << 8) +
                              U32.from[U8](bytes(3)?))

    let data: Array[U8] val = recover
      let d = Array[U8](size)
      bytes.copy_to(d, 4, 0, size)
      consume d
    end

    // Data comes in quartets of bytes, find the quartet size
    let quartet_size = (((size - 1) / 4) + 1) * 4

    (OSCBlob(data), recover bytes.slice(4 + quartet_size) end)

  fun to_type_byte(): U8 =>
    'b'

  fun val value(): Array[U8] val => _data

class OSCTrue is OSCData
  let _data: Bool
  new val create() =>
    _data = true

  fun val to_bytes(): Array[U8 val] val =>
    recover Array[U8](0) end

  fun val from_bytes(bytes: Array[U8] val): (OSCData val, Array[U8] val) =>
    (OSCTrue, recover bytes.slice(0) end)

  fun to_type_byte(): U8 =>
    'T'

  fun val value(): Bool => _data

class OSCFalse is OSCData
  let _data: Bool
  new val create() =>
    _data = true

  fun val to_bytes(): Array[U8 val] val =>
    recover Array[U8](0) end

  fun val from_bytes(bytes: Array[U8] val): (OSCData val, Array[U8] val) =>
    (OSCFalse, recover bytes.slice(0) end)

  fun to_type_byte(): U8 =>
    'F'

  fun val value(): Bool => _data

class OSCTimestamp is OSCData
  let _data: U64

  new val create(data: U64) =>
    _data = data

  fun val to_bytes(): Array[U8] val =>
    recover
      Array[U8]().>push(U8.from[U64]((_data >> 56) and 0xFF))
                 .>push(U8.from[U64]((_data >> 48) and 0xFF))
                 .>push(U8.from[U64]((_data >> 40) and 0xFF))
                 .>push(U8.from[U64]((_data >> 32) and 0xFF))
                 .>push(U8.from[U64]((_data >> 24) and 0xFF))
                 .>push(U8.from[U64]((_data >> 16) and 0xFF))
                 .>push(U8.from[U64]((_data >> 8) and 0xFF))
                 .>push(U8.from[U64]((_data and 0xFF)))
    end

  fun val from_bytes(bytes: Array[U8] val): (OSCData val, Array[U8] val) ? =>
    let data = ((U64.from[U8](bytes(0)?) << 56) +
                (U64.from[U8](bytes(1)?) << 48) +
                (U64.from[U8](bytes(2)?) << 40) +
                (U64.from[U8](bytes(3)?) << 32) +
                (U64.from[U8](bytes(4)?) << 24) +
                (U64.from[U8](bytes(5)?) << 16) +
                (U64.from[U8](bytes(6)?) << 8) +
                U64.from[U8](bytes(7)?))

    (OSCTimestamp(data), recover bytes.slice(8) end)

  fun to_type_byte(): U8 =>
    't'

  fun val value(): U64 => _data

class OSCNull is OSCData
  let _data: None
  new val create() =>
    _data = None

  fun val to_bytes(): Array[U8 val] val =>
    recover Array[U8](0) end

  fun val from_bytes(bytes: Array[U8] val): (OSCData val, Array[U8] val) =>
    (OSCNull, recover bytes.slice(0) end)

  fun to_type_byte(): U8 =>
    'N'

  fun val value(): None => _data

class OSCImpulse is OSCData
  let _data: None
  new val create() =>
    _data = None

  fun val to_bytes(): Array[U8 val] val =>
    recover Array[U8](0) end

  fun val from_bytes(bytes: Array[U8] val): (OSCData val, Array[U8] val) =>
    (OSCImpulse, recover bytes.slice(0) end)

  fun to_type_byte(): U8 =>
    'I'

  fun val value(): None => _data

type Argument is OSCData
type Arguments is Array[Argument val]

class OSCMessage
  """
  This class represents OSC messages, as defined by the OSC standard
  (http://opensoundcontrol.org/). The byte reprsentation of an OSC
  messages consist of an address string, a type string, and zero or
  more arguments. Because the type string can be derived from the
  types of the arguments, the user of this class is not responsible
  for providing a type string when creating an `OSCMessage`.
  """

  let address: String val
  let arguments: Arguments val

  new val create(address': String val, arguments': Arguments val) =>
  """
  Create an OSCMessage from an address string and one or more OSCData
  arguments.
  """
    address = address'
    arguments = arguments'

  fun _build_type_string(): String ref =>
    var arguments_string = String().>push(',')
    for arg in arguments.values() do
      arguments_string.>push(arg.to_type_byte())
    end
    arguments_string

  fun val to_bytes(): Array[U8 val] val =>
  """
  Generate a byte array that represents an OSC message as defined by
  the OSC standard.
  """
    recover
    var parts: Array[U8 val] = Array[U8 val].create()
    var oscAddress = OSCString(address)
    var types = OSCString(_build_type_string().clone())

    parts.concat(oscAddress.to_bytes().values())
    parts.concat(types.to_bytes().values())
    for arg in arguments.values() do
      parts.concat(arg.to_bytes().values())
    end

    parts
    end
