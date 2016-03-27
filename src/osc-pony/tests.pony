use "ponytest"
use "collections"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None
  fun tag tests(test: PonyTest) =>
    test(_TestArgsString)
    test(_TestArgsFloat)
    test(_TestParser)
    test(_TestParserStringLimits)
    test(_TestParserFloatLimits)
    test(_TestParserIntLimits)

class iso _TestArgsString is UnitTest
  fun name(): String => "OSC Arguments: String"

  fun apply(h: TestHelper) =>
    // 0000000 2f 61 00 00 2c 73 00 00 68 69 00 00
    // 000000c
    let x = OscMessage("/a", recover [as OscData val: OscString("hi")] end).toBytes()
    let y = [as U8: '/','a',0,0, ',','s',0,0, 'h','i',0,0]
    h.assert_eq[USize](y.size(), x.size())
    for i in Range[USize](0, y.size().min(x.size())) do
      try
        h.assert_eq[U8](y(i), x(i))
      end
    end


class iso _TestArgsFloat is UnitTest
  fun name(): String => "OSC Arguments: Float"

  fun apply(h: TestHelper) =>
    let x = OscMessage("/a", recover [as OscData val: OscFloat(134.511)] end).toBytes()
    let y = [as U8: '/','a',0,0, ',','f',0,0, 0x43,0x06,0x82,0xd1]
    h.assert_eq[USize](y.size(), x.size())
    for i in Range[USize](0, y.size().min(x.size())) do
      try
        h.assert_eq[U8](y(i), x(i))
      end
    end

class iso _TestParserStringLimits is UnitTest
  fun name(): String => "OSC Parser: StringLimits"

  fun apply(h: TestHelper) =>
    let bytes: Array[U8] val = recover [as U8: 'a','b','c','d', 'q','r',0,0, 'e','f','g',0] end
    try
      let limits = _StringLimits.fromBytes(bytes, 0)
      h.assert_eq[I32](limits.s(), 0)
      h.assert_eq[I32](limits.e(), 7)
      h.assert_eq[I32](limits.sz(), 6)
      h.assert_eq[String](limits.extractFromBytes(bytes), "abcdqr")
    else
      h.assert_eq[Bool](true, false)
    end

    try
      let limits = _StringLimits.fromBytes(bytes, 4)
      h.assert_eq[I32](limits.s(), 4)
      h.assert_eq[I32](limits.e(), 7)
      h.assert_eq[I32](limits.sz(), 2)
      h.assert_eq[String](limits.extractFromBytes(bytes), "qr")
    else
      h.assert_eq[Bool](true, false)
    end

class iso _TestParserIntLimits is UnitTest
  fun name(): String => "OSC Parser: IntLimits"

  fun apply(h: TestHelper) =>
    let bytes: Array[U8] val = recover [as U8: 'a','b','c',0, 0,0,0,1, 'e','f','g',0] end
    try
      let limits = _IntLimits.fromBytes(bytes, 4)
      h.assert_eq[I32](limits.s(), 4)
      h.assert_eq[I32](limits.e(), 7)
      h.assert_eq[I32](limits.sz(), 4)
      h.assert_eq[I32](limits.extractFromBytes(bytes), 1)
    else
      h.assert_eq[Bool](true, false)
    end

class iso _TestParserFloatLimits is UnitTest
  fun name(): String => "OSC Parser: FloatLimits"

  fun apply(h: TestHelper) =>
    let bytes: Array[U8] val = recover [as U8: 'a','b','c',0, 0x43,0x06,0x82,0xd1, 'e','f','g',0] end
    try
      let limits = _FloatLimits.fromBytes(bytes, 4)
      h.assert_eq[I32](limits.s(), 4)
      h.assert_eq[I32](limits.e(), 7)
      h.assert_eq[I32](limits.sz(), 4)
      h.assert_eq[F32](limits.extractFromBytes(bytes), 134.511)
    else
      h.assert_eq[Bool](true, false)
    end

class iso _TestParser is UnitTest
  fun name(): String => "OSC Parser"

  fun apply(h: TestHelper) =>
    let x: Array[U8] val = recover [as U8: '/','a','b','c', 0,0,0,0, ',','f','i','s', 0,0,0,0, 0xe3,0x06,0x82,0xd1, 0,0,0,2, 'a','b',0,0] end
    try
      let y = OscMessage.fromBytes(x).toBytes()
      h.assert_eq[USize](x.size(), y.size())
      for i in Range[USize](0, y.size().min(x.size())) do
        try
          h.assert_eq[U8](x(i), y(i))
        else
          h.assert_eq[Bool](true, false)
        end
      end
    else
      h.assert_eq[Bool](true, false)
    end
