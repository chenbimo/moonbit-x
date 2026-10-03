# chensuiyi/fndash

lodash-style utilities · 通用工具函数

<table>
<tr>
<th width="50%">中文</th>
<th width="50%">English</th>
</tr>
<tr>
<td valign="top">

纯函数工具集:字符串裁剪、严格整数解析、引号值提取、JSON 拼装、百分号编码。

- `jobj` 接收已编码的值片段:可选字段不出现在输入里,就不会以 null 出现在线上
- `parse_int` 严格模式:非纯数字一律 `None`
- 准入规则:纯函数、零依赖、有测试,不收带 I/O 的函数

</td>
<td valign="top">

Pure-function toolkit: string trimming, strict integer parsing, quoted-value extraction, JSON assembly, percent-encoding.

- `jobj` takes pre-encoded value fragments: an optional field absent from the input never becomes a null on the wire
- `parse_int` is strict: anything non-numeric is `None`, never a partial value
- Admission rule: pure, zero-dependency, tested — no I/O functions

</td>
</tr>
</table>

## API

| 接口 Interface | 说明 Description |
| --- | --- |
| `trim_spaces(text)` | 去两端空白(容忍 CRLF);Trim both ends, CRLF-tolerant |
| `parse_int(text)` | 严格整数;Strict digits-only int |
| `quoted_value(line)` | 首个引号段;First double-quoted segment |
| `json_escape` / `jstr` / `jobj` / `jarr` | JSON 拼装;JSON building blocks |
| `url_encode(text)` | 百分号编码;Percent-encoding |

License: MIT
