# dcipc

MoonBit 本地守护进程控制通道:长度前缀帧协议、共享令牌认证(loopback TCP)、状态目录接触文件(port / token)。异步(async 运行时)。

```moonbit
// 守护进程侧
let token = @dcipc.generate_token()
let conn = @dcipc.accept_authed(server, token)        // 认证失败的连接就地关闭
@dcipc.write_frame(conn, response_payload)

// 客户端侧
let conn = @dcipc.dial(state_dir)
let resp = @dcipc.round_trip_bytes(conn, token, request_payload, timeout_ms=5000)
```

- 认证先行:token 帧后服务端回单字节确认,拒绝 = 直接断连——错误 token 呈现为 EOF 而非协议错误
- 常量时间 token 比较,时序不泄露前缀
- 帧上限 4MB(防恶意对端迫使超额分配);握手指令与静默客户端均有 5s 超时
- 接触文件:`daemon.port` + `daemon.token` 写入状态目录,`read_daemon_port`/`read_token` 容忍缺失(视为无守护进程)
- 传输层为 loopback TCP;协议(帧/令牌/认证)与传输解耦,Unix socket 等传输可作为后续扩展点
- 依赖:`moonbitlang/async`(事件循环)+ `chensuiyi/fsx`(接触文件读取)

## License

MIT
