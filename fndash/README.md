# chensuiyi/fndash

lodash-style pure-function utilities for MoonBit: string trimming, strict integer parsing, quoted-value extraction, JSON assembly, percent-encoding. Zero dependencies.

## Install

```bash
moon add chensuiyi/fndash
```

## API

| Interface | Description |
| --- | --- |
| `trim_spaces(text)` | Trim both ends, CRLF-tolerant |
| `parse_int(text)` | Strict digits-only int |
| `quoted_value(line)` | First double-quoted segment |
| `json_escape` / `jstr` / `jobj` / `jarr` | JSON building blocks |
| `url_encode(text)` | Percent-encoding |

Admission rule: pure functions, zero dependencies, tested — no I/O functions.

<details>
<summary><strong>中文说明</strong></summary>

# chensuiyi/fndash

纯函数工具集:字符串裁剪、严格整数解析、引号值提取、JSON 拼装、百分号编码。

- `jobj` 接收已编码的值片段:可选字段不出现在输入里,就不会以 null 出现在线上
- `parse_int` 严格模式:非纯数字一律 `None`
- 准入规则:纯函数、零依赖、有测试,不收带 I/O 的函数

</details>

## License

MIT
