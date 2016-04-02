# osc-pony

`osc-pony` is a [Pony](http://ponylang.org) library for encoding and
decoding Open Sound Control (http://opensoundcontrol.org/)
messages. The library does not provide a means of sending and
receiving these messages over a network connection, however the
`example` directory includes examples which demonstrate how to do
this.

## Overview

The library provides an `OscMessage` class which can be used to
construct OSC messages and generate byte arrays which represent these
messages in the OSC format, as well as to decode a byte array into an
`OscMessage` class which can then be used within a Pony
program. Currently the system supports the three basic OSC message
argument types, string (`OscString`), 32-bit float (OscFloat), and
32-bit twos-complement signed integer (OscInt). While the OSC standard
describes several other message types and allows for arbitrary message
types, these three types are sufficient for using most OSC-compatible
programs, such as
[Reaktor](http://www.native-instruments.com/en/products/komplete/synths/reaktor-6/),
[PureData](http://puredata.info),
[Max/MSP](https://cycling74.com/products/max/),
[SuperCollider](http://supercollider.github.io)/[Overtone](http://overtone.github.io),
and [Chuck](http://chuck.cs.princeton.edu). User-defined argument
types can be defined for creating a message to be encoded, but are not
currently supported for message decoding.

## The Examples

There are two example programs in `src/examples`. One sends an OSC
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
ponyc src/examples/receive/
ponyc src/send/send/
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
  let message = OscMessage('/my/address', recover [as OscData: OscInt(42), OscFloat(3.14159), OscString("this is a string")] end)
  let bytes = message.toBytes()

  // now do something with these bytes ...
```

To receive an OSC message and print out its address and arguments:

```
  let data: Array[U8] val = ... // data from somewhere

  let message = OSCParser.fromBytes(data)
  _env.out.print("Address: ".add(message.address))
  for arg in message.arguments.values() do
    match arg
    | let i: OscInt val => _env.out.print(" int: ".add(i.value().string()))
    | let f: OscFloat val => _env.out.print(" float: ".add(f.value().string()))
    | let s: OscString val => _env.out.print(" string: ".add(s.value()))
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
* Support user-defined argument types.