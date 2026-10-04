# chensuiyi/mwork

moon.work / moon.mod workspace toolkit for MoonBit: parse the member list and module manifests, topologically sort members by dependencies, rewrite version lines and import pins. Parsing is powered by `moonbitlang/moon_config` (toolchain-grade).

## Install

```bash
moon add chensuiyi/mwork
```

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

<details>
<summary><strong>中文文档</strong></summary>

# chensuiyi/mwork

MoonBit 工作区清单工具:解析 `moon.work` 成员列表与 `moon.mod` 清单(name / version / imports),按依赖关系做稳定拓扑排序,重写版本行与 import pin。解析由 `moonbitlang/moon_config` 驱动。

## 安装

```bash
moon add chensuiyi/mwork
```

## 功能

- `parse_members`:从 moon.work 提取成员目录
- `parse_mod`:清单 → `Member`(name / version / 去 @version 的 import 路径),由 `moonbitlang/moon_config` 驱动
- `topo_sort`:Kahn 算法,平局保持 moon.work 声明顺序
- `sync_pins`:按给定版本重写 manifest 内的 import pin(保留行格式)
- `replace_version`:重写首个精确匹配的 `version = "old"` 行

## 场景

- 发布编排:按拓扑序 bump + publish 全体成员
- 工作区分析:谁依赖谁、哪个 pin 过期

## API

| 函数 | 说明 |
| --- | --- |
| `parse_members(text)` | 从 moon.work 提取成员目录 |
| `parse_mod(dir, text)` | 清单 → `Member` |
| `topo_sort(selected, items)` | 被依赖者先,稳定排序 |
| `replace_version(text, old, next)` | 重写首个精确匹配的版本行 |
| `sync_pins(text, pins)` | 按给定版本重写 import pin |

## 用法示例

```moonbit
// 解析工作区、拓扑排序、bump、同步 pin
let dirs = @mwork.parse_members(moon_work_text)
let members = dirs.map(fn(d) { @mwork.parse_mod(d, read(d)) })
let order = @mwork.topo_sort(selected, members)

let text = @mwork.replace_version(manifest, "0.1.0", "0.2.0")
let synced = @mwork.sync_pins(manifest, [("chensuiyi/fndash", "0.2.0")])
```

## 作者

**陈随易** ([@chenbimo](https://github.com/chenbimo))

## 协议

MIT

</details>
