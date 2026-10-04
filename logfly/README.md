# chensuiyi/logfly

Logging for MoonBit: plain text / JSONL line formats with automatic ISO timestamps, plus size-triggered rotation in rename or copytruncate mode.

## Install

```bash
moon add chensuiyi/logfly
```

## API

| Interface | Description |
| --- | --- |
| `plain(path, text)` | Timestamp-prefixed text line |
| `event(path, event, fields)` | JSONL event line |
| `maybe_rotate(path, max, copytruncate?)` | Rotate past limit, returns rotated |

- `plain`: one timestamp-prefixed text line — crash records, human-read logs
- `event`: a JSONL management event; values arrive as pre-encoded fragments, so fields the caller omits never appear on the wire
- `maybe_rotate`: rotate past a size limit; a missing file is not an error
- Depends on `chensuiyi/fsx` + `chensuiyi/dateku` + `chensuiyi/fndash`

<details>
<summary><strong>中文说明</strong></summary>

# chensuiyi/logfly

日志库:纯文本 / JSONL 两种行格式,自动 ISO 时间戳,按大小触发轮转(rename 与 copytruncate 双模式)。

- `plain`:一行时间戳前缀文本——崩溃记录、人读日志
- `event`:JSONL 管理事件,值传已编码片段——调用方省略的字段就不会出现在线上
- `maybe_rotate`:超限轮转;文件不存在不算错
- 依赖:`chensuiyi/fsx` + `chensuiyi/dateku` + `chensuiyi/fndash`

</details>

## License

MIT
