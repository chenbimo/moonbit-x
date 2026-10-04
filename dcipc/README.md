# chensuiyi/dcipc

Control channel for local daemons: length-prefixed frames, shared-token authentication over loopback TCP, and contact files (port / token) in the state dir. Asynchronous (async runtime).

## Install

```bash
moon add chensuiyi/dcipc
```

## API

| Interface | Description |
| --- | --- |
| `generate_token()` | 256 bits from the kernel RNG |
| `dial(state_dir)` | Connect via the port file |
| `accept_authed(server, token)` | Accept + authenticate |
| `round_trip_bytes(conn, token, payload, timeout_ms)` | Authenticated round trip |
| `read_frame_timeout(conn, timeout_ms)` | Read one frame, silence-tolerant |
| `read_token` / `read_daemon_port` | Contact files |

- Auth first: the server acks the token frame with one byte; rejection closes the connection, so a wrong token surfaces as EOF rather than a protocol error
- Constant-time token comparison — timing does not reveal a matching prefix
- 4 MB frame ceiling; 5 s timeouts on the handshake and silent clients
- Protocol is transport-agnostic: Unix sockets and other transports are future extension points
- Depends on `moonbitlang/async` + `chensuiyi/fsx`

<details>
<summary><strong>中文说明</strong></summary>

# chensuiyi/dcipc

本地守护进程控制通道:长度前缀帧协议、共享令牌认证(loopback TCP)、状态目录接触文件(port / token)。异步(async 运行时)。

- 认证先行:token 帧后服务端回单字节确认,拒绝 = 直接断连——错误 token 呈现为 EOF 而非协议错误
- 常量时间 token 比较,时序不泄露前缀
- 帧上限 4MB;握手与静默客户端均有 5s 超时
- 协议与传输解耦:Unix socket 等传输可作为后续扩展点
- 依赖:`moonbitlang/async` + `chensuiyi/fsx`

</details>

## License

MIT
