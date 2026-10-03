# semver

MoonBit 语义版本库:宽松解析、比较、major/minor/patch 递增。

```moonbit
let v = @semver.parse("bun 1.4.0 (official)")   // (1, 4, 0)
@semver.compare(v, @semver.parse("1.5.0")) < 0  // true
@semver.bump(v, @semver.Bump::Minor).to_string() // "1.5.0"
```

- `parse` 刻意宽松:跳过任意前缀(`v`、产品名),停在首个非版本字符,预发布后缀(`1.4.0-beta`)按发布三元组比较;无数字得到全零(调用方可视为"未知版本")
- `compare` 逐段 ordering,返回 -1/0/1
- `bump` 递增一段、清零低位段

## License

MIT
