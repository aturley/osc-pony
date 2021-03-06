# osc-pony

`osc-pony` is a [Pony](http://ponylang.org) library for encoding and
decoding [Open Sound Control](http://opensoundcontrol.org/)
messages. The library does not provide a means of sending and
receiving these messages over a network connection, however the
`example` directory includes examples which demonstrate how to do
this.

## Overview

The library provides an `OSCMessage` class which can be used to
construct OSC messages and generate byte arrays which represent these
messages in the OSC format, as well as to decode a byte array into an
`OSCMessage` class which can then be used within a Pony
program. Currently the system supports all of the OSC argument types
from the
[OSC 1.1 specification](http://opensoundcontrol.org/spec-1_1). This
should be suffiecient to use with systems like
[Reaktor](http://www.native-instruments.com/en/products/komplete/synths/reaktor-6/),
[PureData](http://puredata.info),
[Max/MSP](https://cycling74.com/products/max/),
[SuperCollider](http://supercollider.github.io)/[Overtone](http://overtone.github.io),
and [Chuck](http://chuck.cs.princeton.edu). User-defined argument
types can also be added for encoding and decoding.

## The Examples

There are two example programs in `examples`. One sends an OSC
message, the other waits for incoming OSC messages and when it
receives them it prints out the message address and arguments. By
default the programs will work together, so that if you are running
the `receive` program and you send a message from the `send` program,
you will see the contents of the sent message in the window where you
are running `receive`. The `send` program also sends a message that is
compatible with the `OSC_recv.ck` program that ships with the source
code of the Chuck programming language.

### Building the Examples

From the directory where you checked out `osc-pony`, run:

```
ponyc examples/receive/
ponyc examples/send/
```

Now, in one terminal window run the `receive` program:

```
./receive
```

In another terminal window, run the `send` program:

```
./send
```

You should see a message in the terminal window where you ran the
`receive` program that looks like this:

```
Address: /sndbuf/buf/rate
 float: 0.2
```

## Sample Code

To create an OSC message with integer, float, and string arguments with the address `/my/address`:

```
  let message = OSCMessage('/my/address', 
    recover [as OSCData: OSCInt(42), OSCFloat(3.14159), 
      OSCString("this is a string")] 
    end)
  let bytes = message.to_bytes()

  // now do something with these bytes ...
```

To receive an OSC message and print out its address and arguments:

```
  let data: Array[U8] val = ... // data from somewhere

  let message = OSCParser.from_bytes(data)
  _env.out.print("Address: ".add(message.address))
  for arg in message.arguments.values() do
    match arg
    | let i: OSCInt val => _env.out.print(" int: ".add(i.value().string()))
    | let f: OSCFloat val => _env.out.print(" float: ".add(f.value().string()))
    | let s: OSCString val => _env.out.print(" string: ".add(s.value()))
    else
      _env.err.print("Unknown argument type, this shouldn't happen.")
    end
  end
```

## Using the Library

You can use the library with your own code by using it with the `use`
keyword and passing the location of the library to the compiler with
the `--path` argument. For example, your program would contain the line:

```
use "osc-pony"
```

Assuming that all of your pony libraries are in a directory called
`/pony/libraries` and your program was in a directory called
`/my/program` you would run `ponyc` like this:

```
ponyc --path=/pony/libraries /my/program
```

## TODO

* Support bundles
