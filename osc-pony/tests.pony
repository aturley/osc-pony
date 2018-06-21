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
    test(_TestParserBlob)

class iso _TestArgsString is UnitTest
  fun name(): String => "OSC Arguments: String"

  fun apply(h: TestHelper) =>
    // 0000000 2f 61 00 00 2c 73 00 00 68 69 00 00
    // 000000c
    let x = OSCMessage("/a", recover [as OSCData val: OSCString("hi")] end).to_bytes()
    let y = [as U8: '/';'a';0;0; ',';'s';0;0; 'h';'i';0;0]
    h.assert_eq[USize](y.size(), x.size())
    for i in Range[USize](0, y.size().min(x.size())) do
      try
        h.assert_eq[U8](y(i)?, x(i)?)
      end
    end

class iso _TestArgsFloat is UnitTest
  fun name(): String => "OSC Arguments: Float"

  fun apply(h: TestHelper) =>
    let x = OSCMessage("/a", recover [as OSCData val: OSCFloat(134.511)] end).to_bytes()
    let y = [as U8: '/';'a';0;0; ',';'f';0;0; 0x43;0x06;0x82;0xd1]
    h.assert_eq[USize](y.size(), x.size())
    for i in Range[USize](0, y.size().min(x.size())) do
      try
        h.assert_eq[U8](y(i)?, x(i)?)
      end
    end

class iso _TestParserStringLimits is UnitTest
  fun name(): String => "OSC Parser: StringLimits"

  fun apply(h: TestHelper) =>
    let bytes: Array[U8] val = recover [as U8: 'a';'b';'c';'d'; 'q';'r';0;0; 'e';'f';'g';0] end
    try
      (let str, let rest) = OSCString("").from_bytes(bytes)?
      h.assert_eq[USize](rest.size(), 4)
      match str
      | let s: OSCString val =>
        h.assert_eq[String](s.value(), "abcdqr")
      else
        h.fail()
      end
    else
      h.fail()
    end

    try
      var rest: Array[U8] val
      (_, rest) = OSCString("").from_bytes(bytes)?
      (let str, rest) = OSCString("").from_bytes(rest)?
      h.assert_eq[USize](rest.size(), 0)
      match str
      | let s: OSCString val =>
        h.assert_eq[String](s.value(), "efg")
      else
        h.fail()
      end
    else
      h.fail()
    end

class iso _TestParserIntLimits is UnitTest
  fun name(): String => "OSC Parser: IntLimits"

  fun apply(h: TestHelper) =>
    let bytes: Array[U8] val = recover [as U8: 0;0;0;1; 'e';'f';'g';0] end
    try
      (let int, let rest) = OSCInt(0).from_bytes(bytes)?
      h.assert_eq[USize](rest.size(), 4)
      match int
      | let i: OSCInt val =>
        h.assert_eq[I32](i.value(), 1)
      else
        h.fail()
      end
    else
      h.fail()
    end

class iso _TestParserFloatLimits is UnitTest
  fun name(): String => "OSC Parser: FloatLimits"

  fun apply(h: TestHelper) =>
    let bytes: Array[U8] val = recover [as U8: 0x43;0x06;0x82;0xd1; 'e';'f';'g';0] end
    try
      (let float, let rest) = OSCFloat(0).from_bytes(bytes)?
      h.assert_eq[USize](rest.size(), 4)
      match float
      | let f: OSCFloat val =>
        h.assert_eq[F32](f.value(), 134.511)
      else
        h.fail()
      end
    else
      h.fail()
    end

class iso _TestParserBlob is UnitTest
  fun name(): String => "OSC Parser: Blob"

  fun apply(h: TestHelper) =>
    let bytes: Array[U8] val = recover [as U8: 0x00;0x00;0x00;0x02; 'e';'f';0;0; 'a'; 'b'; 'c'; 'd'] end
    try
      (let blob, let rest) = OSCBlob(recover [as U8: 1] end).from_bytes(bytes)?
      h.assert_eq[USize](rest.size(), 4)
      match blob
      | let b: OSCBlob val =>
        h.assert_eq[USize](2, b.value().size())
        h.assert_eq[U8]('e', b.value()(0)?)
        h.assert_eq[U8]('f', b.value()(1)?)
      else
        h.fail()
      end
    else
      h.fail()
    end

class iso _TestParser is UnitTest
  fun name(): String => "OSC Parser"

  fun apply(h: TestHelper) =>
    let x: Array[U8] val = recover [as U8: '/';'a';'b';'c'; 0;0;0;0
                                           ';';'f';'i';'s'; 'b';'T';'F';'I'; 'N';'s';'t';0
                                           0xe3;0x06;0x82;0xd1; 0;0;0;2
                                           'a';'b';0;0
                                           0;0;0;3; 'e';'f';'g';0
                                           'a';0;0;0
                                           0;0;0;0; 0;0;0;1] end
    try
      let y = OSCDecoder.from_bytes(x)?.to_bytes()
      h.assert_eq[USize](x.size(), y.size())
      for i in Range[USize](0, y.size().min(x.size())) do
        try
          h.assert_eq[U8](x(i)?, y(i)?)
        else
          h.fail()
        end
      end
    else
      h.fail()
    end
