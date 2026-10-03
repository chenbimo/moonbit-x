# chensuiyi/logfly

Logging · 日志

<table>
<tr>
<th width="50%">中文</th>
<th width="50%">English</th>
</tr>
<tr>
<td valign="top">

日志库:纯文本 / JSONL 两种行格式,自动 ISO 时间戳,按大小触发轮转(rename 与 copytruncate 双模式)。

- `plain`:一行时间戳前缀文本——崩溃记录、人读日志
- `event`:JSONL 管理事件,值传已编码片段——调用方省略的字段就不会出现在线上
- `maybe_rotate`:超限轮转;文件不存在不算错
- 依赖:`chensuiyi/fsx` + `chensuiyi/dateku` + `chensuiyi/fndash`

</td>
<td valign="top">

Logging: plain text and JSONL line formats with automatic ISO timestamps, plus size-triggered rotation in rename or copytruncate mode.

- `plain`: one timestamp-prefixed text line — crash records, human-read logs
- `event`: a JSONL management event; values arrive as pre-encoded fragments, so fields the caller omits never appear on the wire
- `maybe_rotate`: rotate past a size limit; a missing file is not an error
- Depends on `chensuiyi/fsx` + `chensuiyi/dateku` + `chensuiyi/fndash`

</td>
</tr>
</table>

## API

| 接口 Interface | 说明 Description |
| --- | --- |
| `plain(path, text)` | `ts text` 文本行;Timestamp-prefixed text line |
| `event(path, event, fields)` | JSONL 事件行;JSONL event line |
| `maybe_rotate(path, max, copytruncate?)` | 超限轮转,返回是否轮转;Rotate past limit, returns rotated |

License: MIT
