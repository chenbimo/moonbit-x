# fndash

MoonBit 通用工具函数库(lodash 风格):字符串裁剪、严格整数解析、引号值提取、JSON 拼装、百分号编码。

```moonbit
@fndash.trim_spaces("  x\r")        // "x"
@fndash.parse_int("42")             // Some(42)
@fndash.quoted_value("k = \"v\"")   // "v"
@fndash.jobj([("msg", @fndash.jstr("hi")), ("n", "1")])
@fndash.url_encode("a b")           // "a%20b"
```

- `jobj` 接收已编码的值片段:可选字段不出现在输入数组里,就不会以 null 出现在线上
- `parse_int` 严格模式:非纯数字一律 `None`,不返回残缺值
- 准入规则:纯函数、零依赖、有测试,不收带 I/O 的函数

## License

MIT
