# chensuiyi/semver

Semantic versioning for MoonBit: lenient parsing, comparison, and major/minor/patch bumping.

<details>
<summary><strong>中文文档</strong></summary>

## 简介

语义版本:宽松解析、比较、major/minor/patch 递增。

## 功能

- `parse` 刻意宽松:跳过任意前缀,预发布后缀按发布三元组比较,无数字得全零
- `compare` 逐段 ordering,返回 -1/0/1
- `bump` 递增一段、清零低位段

## 场景

- 发布编排:按拓扑序给工作区成员统一递增版本
- 运行时版本检查:解析 `--version` 输出并与最低要求比较

</details>

## Features

- `parse` is deliberately lenient: any prefix is skipped (`v`, product names), pre-release suffixes compare as their release triple, text without digits yields all zeros (treat as "unknown version")
- `compare` is segment-by-segment ordering: -1, 0, or 1
- `bump` increments one segment and zeroes the ones below

## Scenarios

- Release orchestration: bump all workspace members in dependency order
- Runtime version checks: parse `--version` output, compare against a minimum

## API

| Function | Description |
| --- | --- |
| `parse(text)` | Lenient extraction of the first triple |
| `compare(a, b)` | -1 / 0 / 1 |
| `bump(v, kind)` | `Major` / `Minor` / `Patch` increment |

<details>
<summary><strong>用法示例 / usage</strong></summary>

```moonbit
let found = @semver.parse("mycli 2.28.1")     // (2, 28, 1)
@semver.compare(found, @semver.parse("2.99.0")) < 0
let next = @semver.bump(found, @semver.Bump::Minor)
next.to_string()                               // "2.29.0"
```

</details>

## Author

**陈随易** ([@chenbimo](https://github.com/chenbimo)) · [mooncakes: chensuiyi](https://mooncakes.io/user/chensuiyi)

## License

MIT
