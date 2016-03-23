use "ponytest"
use "collections"

actor Main is TestList
  new create(env: Env) => PonyTest(env, this)
  new make() => None
  fun tag tests(test: PonyTest) =>
    test(_TestArgsString)
    test(_TestArgsFloat)
    test(_TestParser)


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

class iso _TestParser is UnitTest
  fun name(): String => "OSC Parser"

  fun apply(h: TestHelper) =>
    let x = [as U8: '/','a','b', 'c', 0,0,0,0, ',','f',0,0, 0xe3,0x06,0x82,0xd1]
    try
      let y = OscParser.parse(x).toBytes()
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
