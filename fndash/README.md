# chensuiyi/fndash

lodash-style pure-function utilities for MoonBit: string trimming and padding, strict integer parsing, prefix/suffix handling, case conversion, JSON assembly, percent-encoding, array chunk/uniq/range, clamping, and hex codecs. Zero dependencies.

## Install

```bash
moon add chensuiyi/fndash
```

## Features

- Strings: `trim_spaces` (CRLF-tolerant), `pad_start` / `pad_end` (multi-char pad), `to_lower` / `to_upper` (Latin), `remove_prefix` / `remove_suffix` (`None` when absent), `is_blank`
- Parsing: `parse_int` is strict digits-only — non-numeric is `None`, never a partial value; `quoted_value` pulls the first double-quoted segment
- JSON: `json_escape` / `jstr` / `jobj` / `jarr` — optional fields absent from the input never become nulls on the wire
- Encoding: `url_encode` (RFC 3986 unreserved over UTF-8), `hex_encode` / `hex_decode` (uppercase, `None` on bad input)
- Arrays: `chunk[T]`, `uniq[T : Eq]` (order-preserving), `range(start, end, step?)`, `clamp_int`

## Scenarios

- Line-based config / manifest parsing (`key = "value"` shapes)
- Streaming JSON assembly for API payloads
- Query-string and form-body encoding, hex serialization of bytes
- Padding numbers and slicing data into batches

## API

| Function | Description |
| --- | --- |
| `trim_spaces(text)` | Trim both ends, CRLF-tolerant |
| `parse_int(text)` | Strict digits-only int, else `None` |
| `quoted_value(line)` | First double-quoted segment |
| `is_blank(text)` | Empty or spaces/tabs only |
| `remove_prefix(text, prefix)` | Drop prefix, `None` when absent |
| `remove_suffix(text, suffix)` | Drop suffix, `None` when absent |
| `pad_start(text, len, pad?)` | Left-pad, default `"0"` |
| `pad_end(text, len, pad?)` | Right-pad, default `" "` |
| `to_lower(text)` / `to_upper(text)` | Latin case conversion |
| `split(text, sep)` | Split into owned strings |
| `json_escape(text)` | Escape for a JSON string literal |
| `jstr(text)` | Quoted + escaped JSON string |
| `jobj(fields)` | JSON object from pre-encoded fragments |
| `jarr(items)` | JSON array from pre-encoded fragments |
| `url_encode(text)` | Percent-encode over UTF-8 |
| `hex_encode(bytes)` | Bytes as uppercase hex |
| `hex_decode(text)` | Hex to bytes, `None` on bad input |
| `chunk[T](items, size)` | Consecutive chunks of at most `size` |
| `uniq[T : Eq](items)` | First occurrence of each, order kept |
| `range(start, end, step?)` | Integers `start` up to `end` by `step` |
| `clamp_int(n, lo, hi)` | Clamp into `[lo, hi]` |

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
@fndash.parse_int("42")                            // Some(42)
@fndash.parse_int("4x")                            // None

// String helpers
@fndash.pad_start("42", 5)                         // "00042"
@fndash.remove_prefix("v1.2.3", "v")               // Some("1.2.3")
@fndash.split("a,b,c", ",")                        // ["a", "b", "c"]

// Encoding
@fndash.url_encode("a b&c=1")                      // "a%20b%26c%3D1"
@fndash.hex_decode("4142")                         // Some(b"AB")

// Arrays
@fndash.chunk([1, 2, 3, 4, 5], 2)                  // [[1, 2], [3, 4], [5]]
@fndash.uniq(["a", "b", "a"])                      // ["a", "b"]
@fndash.range(0, 5, step=2)                        // [0, 2, 4]
@fndash.clamp_int(99, 1, 10)                       // 10
```

</details>

## Author

**陈随易** ([@chenbimo](https://github.com/chenbimo)) · [mooncakes: chensuiyi](https://mooncakes.io/user/chensuiyi)

## License

MIT

<details>
<summary><strong>中文文档</strong></summary>

# chensuiyi/fndash

MoonBit 纯函数工具集(lodash 风格):字符串裁剪与填充、严格整数解析、前后缀处理、大小写转换、JSON 拼装、百分号编码、数组分块/去重/区间、夹取与 hex 编解码。零依赖。

## 安装

```bash
moon add chensuiyi/fndash
```

## 功能

- 字符串:`trim_spaces`(容忍 CRLF)、`pad_start` / `pad_end`(多字符 pad)、`to_lower` / `to_upper`(Latin)、`remove_prefix` / `remove_suffix`(不存在返回 `None`)、`is_blank`
- 解析:`parse_int` 严格纯数字——非数字一律 `None`,绝不返回残缺值;`quoted_value` 取首个双引号段
- JSON:`json_escape` / `jstr` / `jobj` / `jarr`——输入里省略的可选字段,绝不会以 null 出现在线上
- 编码:`url_encode`(RFC 3986 unreserved,按 UTF-8)、`hex_encode` / `hex_decode`(大写,非法输入 `None`)
- 数组:`chunk[T]`、`uniq[T : Eq]`(保序)、`range(start, end, step?)`、`clamp_int`

## 场景

- 行级配置 / 清单解析(`key = "value"` 形态)
- API 载荷的流式 JSON 拼装
- 查询串与表单体编码、字节的 hex 序列化
- 数字补零、数据分批

## API

| 函数 | 说明 |
| --- | --- |
| `trim_spaces(text)` | 去两端空白,容忍 CRLF |
| `parse_int(text)` | 严格纯数字整数,否则 `None` |
| `quoted_value(line)` | 首个双引号段 |
| `is_blank(text)` | 空或仅空白/制表符 |
| `remove_prefix(text, prefix)` | 去前缀,不存在返回 `None` |
| `remove_suffix(text, suffix)` | 去后缀,不存在返回 `None` |
| `pad_start(text, len, pad?)` | 左填充,默认补 `"0"` |
| `pad_end(text, len, pad?)` | 右填充,默认补 `" "` |
| `to_lower(text)` / `to_upper(text)` | Latin 大小写转换 |
| `split(text, sep)` | 按分隔符切分 |
| `json_escape(text)` | 转义为 JSON 字符串字面量 |
| `jstr(text)` | 引号包裹 + 转义的 JSON 字符串 |
| `jobj(fields)` | 由已编码片段拼 JSON 对象 |
| `jarr(items)` | 由已编码片段拼 JSON 数组 |
| `url_encode(text)` | 按 UTF-8 百分号编码 |
| `hex_encode(bytes)` | 字节转大写 hex |
| `hex_decode(text)` | hex 转字节,非法返回 `None` |
| `chunk[T](items, size)` | 每块至多 `size` 个的连续分块 |
| `uniq[T : Eq](items)` | 每值取首次出现,保序 |
| `range(start, end, step?)` | 从 `start` 到 `end` 步长 `step` |
| `clamp_int(n, lo, hi)` | 夹取到 `[lo, hi]` |

## 用法示例

```moonbit
// JSON 拼装:省略的可选字段不会以 null 出现在线上
@fndash.jobj([
  ("msg", @fndash.jstr("hello")),
  ("count", "3"),
])

// 清单行解析
@fndash.quoted_value("name = \"chensuiyi/bm2\"")   // "chensuiyi/bm2"
@fndash.parse_int("42")                            // Some(42)
@fndash.parse_int("4x")                            // None

// 字符串工具
@fndash.pad_start("42", 5)                         // "00042"
@fndash.remove_prefix("v1.2.3", "v")               // Some("1.2.3")
@fndash.split("a,b,c", ",")                        // ["a", "b", "c"]

// 编码
@fndash.url_encode("a b&c=1")                      // "a%20b%26c%3D1"
@fndash.hex_decode("4142")                         // Some(b"AB")

// 数组
@fndash.chunk([1, 2, 3, 4, 5], 2)                  // [[1, 2], [3, 4], [5]]
@fndash.uniq(["a", "b", "a"])                      // ["a", "b"]
@fndash.range(0, 5, step=2)                        // [0, 2, 4]
@fndash.clamp_int(99, 1, 10)                       // 10
```

## 作者

**陈随易** ([@chenbimo](https://github.com/chenbimo))

## 协议

MIT

</details>
