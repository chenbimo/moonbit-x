# chensuiyi/fndash

lodash-style pure-function utilities for MoonBit: string trimming, strict integer parsing, quoted-value extraction, JSON assembly, and percent-encoding. Zero dependencies.

## Features

- `trim_spaces`: trim both ends, CRLF-tolerant
- `parse_int`: strict digits-only int — non-numeric is `None`, never a partial value
- `quoted_value`: first double-quoted segment in a line
- `json_escape` / `jstr` / `jobj` / `jarr`: JSON building blocks — optional fields absent from the input never become nulls on the wire
- `url_encode`: percent-encoding over UTF-8

## Scenarios

- Line-based config / manifest parsing (`key = "value"` shapes)
- Streaming JSON assembly for API payloads
- Query-string and form-body encoding

## API

| Function | Description |
| --- | --- |
| `trim_spaces(text)` | Trim both ends, CRLF-tolerant |
| `parse_int(text)` | Strict digits-only int, else `None` |
| `quoted_value(line)` | First double-quoted segment |
| `json_escape(text)` | Escape for embedding in a JSON string |
| `jstr(text)` | Quoted + escaped JSON string |
| `jobj(fields)` | JSON object from pre-encoded fragments |
| `jarr(items)` | JSON array from pre-encoded fragments |
| `url_encode(text)` | Percent-encode over UTF-8 |

<details>
<summary><strong>用法示例 / usage</strong></summary>

```moonbit
// JSON assembly: omitted optional fields never become nulls
@fndash.jobj([
  ("msg", @fndash.jstr("hello")),
  ("count", "3"),
])

// Manifest line parsing
@fndash.quoted_value("name = \"chensuiyi/bm2\"")   // "chensuiyi/bm2"

// Query encoding
@fndash.url_encode("a b&c=1")                      // "a%20b%26c%3D1"
```

</details>

## Author

**陈随易** ([@chenbimo](https://github.com/chenbimo)) · [mooncakes: chensuiyi](https://mooncakes.io/user/chensuiyi)

## License

MIT

<details>
<summary><strong>中文文档</strong></summary>

## 简介

纯函数工具集:字符串裁剪、严格整数解析、引号值提取、JSON 拼装、百分号编码。

## 功能

- `jobj` 接收已编码的值片段:可选字段不出现在输入里,就不会以 null 出现在线上
- `parse_int` 严格模式:非纯数字一律 `None`
- 准入规则:纯函数、零依赖、有测试,不收带 I/O 的函数

## 场景

- 配置/清单文件的行级解析(引号值、键值对)
- 流式拼装 JSON(可选字段省略即不出现在线上)
- URL 查询串与表单编码

</details>
