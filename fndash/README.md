# chensuiyi/fndash

lodash-style pure-function utilities for MoonBit: string trimming, strict integer parsing, quoted-value extraction, JSON assembly, and percent-encoding. Zero dependencies.

## Install

```bash
moon add chensuiyi/fndash
```

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

# chensuiyi/fndash

MoonBit 纯函数工具集(lodash 风格):字符串裁剪、严格整数解析、引号值提取、JSON 拼装、百分号编码。零依赖。

## 安装

```bash
moon add chensuiyi/fndash
```

## 功能

- `trim_spaces`:去两端空白,容忍 CRLF
- `parse_int`:严格纯数字整数——非数字一律 `None`,绝不返回残缺值
- `quoted_value`:行内首个双引号段
- `json_escape` / `jstr` / `jobj` / `jarr`:JSON 拼装积木——输入里省略的可选字段,绝不会以 null 出现在线上
- `url_encode`:按 UTF-8 百分号编码

## 场景

- 行级配置 / 清单解析(`key = "value"` 形态)
- API 载荷的流式 JSON 拼装
- 查询串与表单体编码

## API

| 函数 | 说明 |
| --- | --- |
| `trim_spaces(text)` | 去两端空白,容忍 CRLF |
| `parse_int(text)` | 严格纯数字整数,否则 `None` |
| `quoted_value(line)` | 首个双引号段 |
| `json_escape(text)` | 转义为可嵌入 JSON 字符串 |
| `jstr(text)` | 引号包裹 + 转义的 JSON 字符串 |
| `jobj(fields)` | 由已编码片段拼 JSON 对象 |
| `jarr(items)` | 由已编码片段拼 JSON 数组 |
| `url_encode(text)` | 按 UTF-8 百分号编码 |

## 用法示例

```moonbit
// JSON 拼装:省略的可选字段不会以 null 出现在线上
@fndash.jobj([
  ("msg", @fndash.jstr("hello")),
  ("count", "3"),
])

// 清单行解析
@fndash.quoted_value("name = \"chensuiyi/bm2\"")   // "chensuiyi/bm2"

// 查询编码
@fndash.url_encode("a b&c=1")                      // "a%20b%26c%3D1"
```

## 作者

**陈随易** ([@chenbimo](https://github.com/chenbimo))

## 协议

MIT

</details>
