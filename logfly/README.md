# logfly

MoonBit 日志库:纯文本 / JSONL 两种行格式,自动 ISO 时间戳,按大小触发轮转(rename 与 copytruncate 双模式)。

```moonbit
@logfly.plain("crash.log", "app=api reason=exit_1")            // "ts text" 行
@logfly.event("bm2d.events.jsonl", "spawn_failed", [
  ("app", @fndash.jstr("api")),
  ("pid", "42"),                                               // 数字留裸值
])
@logfly.maybe_rotate("app.log", 10485760)            // 超 10MB 轮转
```

- `plain`:一行时间戳前缀文本,崩溃记录/人读日志
- `event`:JSONL 管理事件,值传已编码片段——调用方省略的字段就不会出现在线上
- `maybe_rotate`:rename 模式(自己写的日志)/ copytruncate 模式(进程持 fd 的日志),文件不存在不算错
- 依赖:`chensuiyi/fsx`(追加/轮转)+ `chensuiyi/dateku`(时间戳)+ `chensuiyi/fndash`(JSON 拼装)

## License

MIT
