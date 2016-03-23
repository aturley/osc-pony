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
  new val fromBytes(input: Array[U8] val, start: I32) ? =>
    var i = start + 3
    while (i < I32.from[USize](input.size())) and (input(USize.from[I32](i)) != '\0') do
      i = i + 4
    end
    if i >= I32.from[USize](input.size()) then
      error
    end

    var sz': I32 = 1
    while input(USize.from[I32](start + sz')) != '\0' do
      sz' = sz' + 1
    end
    _s = start
    _e = i
    _sz = sz'
  fun extractFromBytes(input: Array[U8] val): String ? =>
    var str = String()

    for i in Range[USize](USize.from[I32](_s), USize.from[I32](_s + _sz)) do
      str.push(input(i))
    end
    str.clone()
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
  new val fromBytes(input: Array[U8] val, start: I32) ? =>
    if (start + 3) > I32.from[USize](input.size()) then
      error
    else
      _s = start
      _e = _s + 3
      _sz = 4
    end
  fun extractFromBytes(input: Array[U8] val): I32 ? =>
    I32.from[U32]((U32.from[U8](input(USize.from[I32](_s))) << 24) +
                  (U32.from[U8](input(USize.from[I32](_s + 1))) << 16) +
                  (U32.from[U8](input(USize.from[I32](_s + 2))) << 8) +
                  (U32.from[U8](input(USize.from[I32](_s + 3)))))
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
  new val fromBytes(input: Array[U8] val, start: I32) ? =>
    if (start + 3) > I32.from[USize](input.size()) then
      error
    else
      _s = start
      _e = _s + 3
      _sz = 4
    end
  fun extractFromBytes(input: Array[U8] val): F32 ? =>
    F32.from_bits((U32.from[U8](input(USize.from[I32](_s))) << 24) +
                  (U32.from[U8](input(USize.from[I32](_s + 1))) << 16) +
                  (U32.from[U8](input(USize.from[I32](_s + 2))) << 8) +
                  (U32.from[U8](input(USize.from[I32](_s + 3)))))
  fun s(): I32 => _s
  fun e(): I32 => _e
  fun sz(): I32 => _sz
