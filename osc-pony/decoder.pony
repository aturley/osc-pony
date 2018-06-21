use "collections"

primitive KnownTypes
  fun types(): Array[OSCData val] val =>
    recover
      [as OSCData val: OSCString(""); OSCInt(0); OSCFloat(0.0)
                       OSCBlob(recover [0] end); OSCTrue; OSCFalse; OSCNull
                       OSCImpulse; OSCTimestamp(0)]
    end

class OSCDecoder
  let _dispatch: Array[(OSCData val | None val)]

  new val create(known_types: Array[OSCData val] val = KnownTypes.types()) =>
    _dispatch = Array[(OSCData val | None val)].init(None, 256)
    for known_type in known_types.values() do
      try
        _dispatch.update((USize.from[U8](known_type.to_type_byte())), known_type)?
      end
    end

  fun from_bytes(input: Array[U8] val): OSCMessage val ? =>
  """
  Take an Array[U8] and create the corresponding OSC Message.
  """
    let string_builder = OSCString("")
    var rest: Array[U8] val

    (let osc_address, rest) = string_builder.from_bytes(input)?

    let address = (osc_address as OSCString val).value()

    (let osc_arg_types, rest) = string_builder.from_bytes(rest)?

    let arg_types = (osc_arg_types as OSCString val).value()

    let args_count = arg_types.size() - 1

    var osc_args: Array[OSCData val] trn = recover Array[OSCData val] end

    for arg_type_index in Range[USize](1, args_count + 1) do
      let builder = _dispatch(USize.from[U8](arg_types(arg_type_index)?))?
      let b = builder as OSCData val
      (let a, rest) = b.from_bytes(rest)?
      osc_args.push(a)
    end

    OSCMessage(address, consume osc_args)
