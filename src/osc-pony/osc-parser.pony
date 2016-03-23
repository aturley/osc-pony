use "collections"

interface Limits
  fun s(): I32
  fun e(): I32
  fun sz(): I32

class StringLimits is Limits
  let _s: I32
  let _e: I32
  let _sz: I32
  new val create(s': I32 val, e': I32 val, sz': I32 val) =>
    _s = s'
    _e = e'
    _sz = sz'
  fun s(): I32 => _s
  fun e(): I32 => _e
  fun sz(): I32 => _sz

class IntLimits
  let _s: I32
  let _e: I32
  let _sz: I32
  new val create(s': I32 val) =>
    _s = s'
    _e = s' + 3
    _sz = 4
  fun s(): I32 => _s
  fun e(): I32 => _e
  fun sz(): I32 => _sz

class FloatLimits
  let _s: I32
  let _e: I32
  let _sz: I32
  new val create(s': I32 val) =>
    _s = s'
    _e = s' + 3
    _sz = 4
  fun s(): I32 => _s
  fun e(): I32 => _e
  fun sz(): I32 => _sz

primitive OscParser
  fun _findString(input: Array[U8], start: I32): StringLimits val ? =>
    var i = start + 3
    while (i < I32.from[USize](input.size())) and (input(USize.from[I32](i)) != '\0') do
      i = i + 4
    end
    if i >= I32.from[USize](input.size()) then
      error
    end

    var sz: I32 = 1
    while input(USize.from[I32](start + sz)) != '\0' do
      sz = sz + 1
    end
    StringLimits(start, i, sz)

  fun _findFloat(input: Array[U8], start: I32): FloatLimits val ? =>
    if (start + 3) > I32.from[USize](input.size()) then
      error
    else
      FloatLimits(start)
    end

  fun _findInt(input: Array[U8], start: I32): IntLimits val ? =>
    if (start + 3) > I32.from[USize](input.size()) then
      error
    else
      IntLimits(start)
    end

  fun _intFromBytes(input: Array[U8], l: IntLimits val): I32 ? =>
    I32.from[U32]((U32.from[U8](input(USize.from[I32](l.s()))) << 24) +
                  (U32.from[U8](input(USize.from[I32](l.s() + 1))) << 16) +
                  (U32.from[U8](input(USize.from[I32](l.s() + 2))) << 8) +
                  (U32.from[U8](input(USize.from[I32](l.s() + 3)))))

  fun _floatFromBytes(input: Array[U8], l: FloatLimits val): F32 ? =>
    F32.from_bits((U32.from[U8](input(USize.from[I32](l.s()))) << 24) +
                  (U32.from[U8](input(USize.from[I32](l.s() + 1))) << 16) +
                  (U32.from[U8](input(USize.from[I32](l.s() + 2))) << 8) +
                  (U32.from[U8](input(USize.from[I32](l.s() + 3)))))

  fun _stringFromBytes(input: Array[U8], l: StringLimits val): String ? =>
    var str = String()

    for i in Range[USize](USize.from[I32](l.s()), USize.from[I32](l.e())) do
      str.push(input(i))
    end
    str.clone()

  fun parse(input: Array[U8]): OscMessage val ? =>
    let addressLimits = _findString(input, 0)
    let typesLimits = _findString(input, addressLimits.e() + 1)
    let argsCount = typesLimits.sz() - 1

    var last: (StringLimits val | FloatLimits val | IntLimits val) = typesLimits
    var argsLimitsArray = Array[Limits val](USize.from[I32](argsCount))

    var oscArgs: Array[OscData val] trn = recover Array[OscData val] end

    for i in Range[I32](1, typesLimits.sz()) do
      last = match input(USize.from[I32](typesLimits.s() + i))
        | 's' =>
          _findString(input, last.e() + 1)
        | 'f' =>
          _findFloat(input, last.e() + 1)
        | 'i' =>
          _findInt(input, last.e() + 1)
        else
          error
        end

      match last
        | let str: StringLimits val =>
          let x = OscString(_stringFromBytes(input, str))
          oscArgs(USize.from[I32](i - 1)) = x
        | let fl: FloatLimits val =>
          let x = OscFloat(_floatFromBytes(input, fl))
          oscArgs(USize.from[I32](i - 1)) = x
        | let int: IntLimits val =>
          let x = OscInt(_intFromBytes(input, int))
          oscArgs(USize.from[I32](i - 1)) = x
      end
    end

    OscMessage(_stringFromBytes(input, addressLimits), consume oscArgs)