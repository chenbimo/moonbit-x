# chensuiyi/logfly

Logging for MoonBit: plain text / JSONL line formats with automatic ISO timestamps, plus size-triggered rotation in rename or copytruncate mode.

<details>
<summary><strong>中文文档</strong></summary>

## 简介

日志库:纯文本 / JSONL 两种行格式,自动 ISO 时间戳,按大小触发轮转(rename 与 copytruncate 双模式)。

## 功能

- `plain`:一行时间戳前缀文本——崩溃记录、人读日志
- `event`:JSONL 管理事件,值传已编码片段——调用方省略的字段就不会出现在线上
- `maybe_rotate`:超限轮转;文件不存在不算错

## 场景

- 守护进程事件日志(JSONL,机器可解析)
- 崩溃记录与人读日志(纯文本)
- 按大小轮转:rename(自写日志)/ copytruncate(进程持 fd)

</details>

## Features

- `plain`: one timestamp-prefixed text line — crash records, human-read logs
- `event`: a JSONL management event; values arrive as pre-encoded fragments, so fields the caller omits never appear on the wire
- `maybe_rotate`: rotate past a size limit in rename or copytruncate mode; a missing file is not an error
- Depends on `chensuiyi/fsx` + `chensuiyi/dateku` + `chensuiyi/fndash`

## Scenarios

- Daemon event logs: JSONL, machine-parseable, dedupe-friendly
- Crash records: plain text, human-read
- Long-running services: size-triggered rotation keeps disk usage bounded

## API

| Function | Description |
| --- | --- |
| `plain(path, text)` | Timestamp-prefixed text line |
| `event(path, event, fields)` | JSONL event line |
| `maybe_rotate(path, max_bytes, copytruncate?)` | Rotate past limit, returns rotated |

<details>
<summary><strong>用法示例 / usage</strong></summary>

```moonbit
// Management event: omitted optional fields never appear on the wire
@logfly.event("/var/lib/app/events.jsonl", "spawn_failed", [
  ("app", @fndash.jstr("api")),
  ("pid", "42"),
])

// Crash record: plain text with automatic timestamp
@logfly.plain("/var/log/app/crash.log", "app=api reason=exit_1")

// Rotate past 10 MB
@logfly.maybe_rotate("/var/log/app/events.jsonl", 10485760)
```

</details>

## Author

**陈随易** ([@chenbimo](https://github.com/chenbimo)) · [mooncakes: chensuiyi](https://mooncakes.io/user/chensuiyi)

## License

MIT
