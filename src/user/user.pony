use "../osc-pony"

actor Main
  new create(env: Env) =>
    let x = OscMessage("/sndbuf/buf/rate", recover [as OscData val: OscFloat(0.2)] end).toBytes()
    env.out.write(x)