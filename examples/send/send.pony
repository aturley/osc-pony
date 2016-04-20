"""
This program sends an OSC message. By default the message is sent
to localhost:6447.  The message is compatible with the
[Chuck](http://chuck.cs.princeton.edu) example OSC program that can
be found in `examples/osc/OSC_recv.ck` when you download the Chuck
source code.
"""

use "../src/osc-pony"

use "net"

class UDPClient is UDPNotify
  let _destination: IPAddress
  let _message: OSCMessage val

  new iso create(env: Env, destination: IPAddress, message: OSCMessage val) =>
    _destination = destination
    _message = message

  fun ref listening(sock: UDPSocket ref) =>
    sock.write(_message.to_bytes(), _destination)
    sock.dispose()

actor Main
  new create(env: Env) =>
    let host = try
      env.args(1)
    else
      "127.0.0.1"
    end

    let port = try
      env.args(2)
    else
      "6447"
    end

    let message = OSCMessage("/sndbuf/buf/rate", recover [as OSCData val: OSCFloat(0.2)] end)
    try
      let auth = env.root as AmbientAuth
      let destination = DNS.ip4(auth, host, port)(0)
      UDPSocket(auth, UDPClient(env, (consume destination), message))
    else
      env.err.print("could not connect")
    end
