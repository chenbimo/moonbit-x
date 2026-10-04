# chensuiyi/semver

Semantic versioning for MoonBit: lenient parsing, comparison, major/minor/patch bumping.

## Install

```bash
moon add chensuiyi/semver
```

## API

| Interface | Description |
| --- | --- |
| `parse(text)` | Lenient extraction of the first triple |
| `compare(a, b)` | -1 / 0 / 1 |
| `bump(v, kind)` | `Major` / `Minor` / `Patch` increment |
| `Semver::to_string` | `1.4.0` |

- `parse` is deliberately lenient: any prefix is skipped, pre-release suffixes compare as their release triple, text without digits yields all zeros

<details>
<summary><strong>中文说明</strong></summary>

# chensuiyi/semver

语义版本:宽松解析、比较、major/minor/patch 递增。

- `parse` 刻意宽松:跳过任意前缀(`v`、产品名),停在首个非版本字符;预发布后缀(`1.4.0-beta`)按发布三元组比较;无数字得全零(可视为"未知版本")
- `compare` 逐段 ordering,返回 -1/0/1
- `bump` 递增一段、清零低位段

</details>

## License

MIT
