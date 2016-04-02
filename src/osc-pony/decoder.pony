use "collections"

primitive KnownTypes
  fun types(): Array[OscData val] val =>
    recover
      [as OscData val: OscString(""), OscInt(0), OscFloat(0.0),
                       OscBlob(recover [0] end), OscTrue, OscFalse, OscNull,
                       OscImpulse, OscTimestamp(0)]
    end

class OSCDecoder
  let _dispatch: Array[(OscData val | None val)]

  new val create(known_types: Array[OscData val] val = KnownTypes.types()) =>
    _dispatch = Array[(OscData val | None val)].init(None, 256)
    for known_type in known_types.values() do
      try
        _dispatch.update((USize.from[U8](known_type.toTypeByte())), known_type)
      end
    end

  fun from_bytes(input: Array[U8] val): OscMessage val ? =>
  """
  Take an Array[U8] and create the corresponding OSC Message.
  """
    let string_builder = OscString("")
    var rest: Array[U8] val

    (let osc_address, rest) = string_builder.fromBytes(input)

    let address = (osc_address as OscString val).value()

    (let osc_arg_types, rest) = string_builder.fromBytes(rest)

    let arg_types = (osc_arg_types as OscString val).value()

    let args_count = arg_types.size() - 1

    var osc_args: Array[OscData val] trn = recover Array[OscData val] end

    for arg_type_index in Range[USize](1, args_count + 1) do
      let builder = _dispatch(USize.from[U8](arg_types(arg_type_index)))
      let b = builder as OscData val
      (let a, rest) = b.fromBytes(rest)
      osc_args.push(a)
    end

    OscMessage(address, consume osc_args)