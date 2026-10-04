# chensuiyi/mwork

moon.work / moon.mod workspace toolkit for MoonBit: parse the member list and module manifests, topologically sort members by dependencies, rewrite version lines and import pins. Parsing is powered by `moonbitlang/moon_config` (toolchain-grade).

<details>
<summary><strong>中文文档</strong></summary>

## 简介

解析 `moon.work` 成员列表与 `moon.mod` 清单(name / version / imports),按依赖关系做稳定拓扑排序,重写版本行与 import pin。解析由 `moonbitlang/moon_config` 驱动。

## 功能

- `parse_mod` 后处理形态:imports 变为 deps 对象,键即去 @version 的模块路径
- `topo_sort` 为 Kahn 算法,平局保持 moon.work 声明顺序
- `sync_pins` / `replace_version` 行级重写,保留原格式

## 场景

- 发布编排:按拓扑序 bump + publish 全体成员
- 工作区分析:谁依赖谁、缺哪个版本

</details>

## Features

- `parse_members`: member directories from moon.work
- `parse_mod`: manifest → `Member` (name / version / import paths, `@version` stripped) via `moonbitlang/moon_config`
- `topo_sort`: Kahn's algorithm, stable on the moon.work declaration order
- `sync_pins`: rewrite import pins across a manifest to given versions (line-preserving)
- `replace_version`: rewrite the first exact `version = "old"` line

## Scenarios

- Release orchestration: bump + publish all members in dependency order
- Workspace analysis: who depends on whom, which pins are stale

## API

| Function | Description |
| --- | --- |
| `parse_members(text)` | Member directories from moon.work |
| `parse_mod(dir, text)` | Manifest → `Member` |
| `topo_sort(selected, items)` | Dependencies first, stable |
| `replace_version(text, old, next)` | Rewrite the first exact version line |
| `sync_pins(text, pins)` | Rewrite import pins to given versions |

<details>
<summary><strong>用法示例 / usage</strong></summary>

```moonbit
// Parse the workspace, topologically sort, bump, sync pins
let dirs = @mwork.parse_members(moon_work_text)
let members = dirs.map(fn(d) { @mwork.parse_mod(d, read(d)) })
let order = @mwork.topo_sort(selected, members)

let text = @mwork.replace_version(manifest, "0.1.0", "0.2.0")
let synced = @mwork.sync_pins(manifest, [("chensuiyi/fndash", "0.2.0")])
```

</details>

## Author

**陈随易** ([@chenbimo](https://github.com/chenbimo)) · [mooncakes: chensuiyi](https://mooncakes.io/user/chensuiyi)

## License

MIT
