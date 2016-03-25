use "../osc-pony"

use "net"

class UdpClient is UDPNotify
  let _env: Env
  let _destination: IPAddress
  let _message: OscMessage val

  new iso create(env: Env, destination: IPAddress, message: OscMessage val) =>
    _env = env
    _destination = destination
    _message = message

  fun ref listening(sock: UDPSocket ref) =>
    sock.write(_message.toBytes(), _destination)
    sock.dispose()

  fun ref not_listening(sock: UDPSocket ref) =>
    None

  fun ref received(sock: UDPSocket ref, data: Array[U8] iso, from: IPAddress) =>
    None

  fun ref closed(sock: UDPSocket ref) =>
    None
    
actor Main
  new create(env: Env) =>
    
    let message = OscMessage("/sndbuf/buf/rate", recover [as OscData val: OscFloat(0.2)] end)
    try
      let destination = DNS.ip4("127.0.0.1", "6449")(0)
      UDPSocket(UdpClient(env, (consume destination), message))
    else
      env.err.print("could not connect")
    end