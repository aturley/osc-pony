"""
This program receives an OSC message. By default the message is
received on localhost:6447.  The message is compatible with the
[Chuck](http://chuck.cs.princeton.edu) example OSC program that can
be found in `examples/osc/OSC_send.ck` when you download the Chuck
source code.
"""

use "../../src/osc-pony"

use "net"

class UDPClient is UDPNotify
  let _env: Env

  new iso create(env: Env) =>
    _env = env

  fun ref received(sock: UDPSocket ref, data: Array[U8] iso, from: IPAddress) =>
    try
      let message = OSCDecoder.from_bytes(consume data) as OSCMessage val
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
    else
      _env.err.print("Error decoding incoming message.")
    end

actor Main
  new create(env: Env) =>
    let host = try
      env.args(1)
    else
      ""
    end

    let port = try
      env.args(2)
    else
      "6447"
    end

    try
      UDPSocket(env.root as AmbientAuth, UDPClient(env), host, port)
    else
      env.err.print("could not connect")
    end
