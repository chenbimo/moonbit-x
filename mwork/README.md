# chensuiyi/mwork

moon.work / moon.mod workspace toolkit for MoonBit: parse the member list and module manifests, topologically sort members by dependencies, and rewrite version lines.

## Install

```bash
moon add chensuiyi/mwork
```

## API

| Interface | Description |
| --- | --- |
| `parse_members(text)` | Member directories from moon.work |
| `parse_mod(dir, text)` | Manifest → `Member` |
| `topo_sort(selected, items)` | Dependencies first, stable |
| `replace_version(text, old, next)` | Rewrite the first version line |
| `sync_pins(text, pins)` | Rewrite import pins to given versions |

- `parse_mod` strips any `@version` suffix from imports, yielding module paths
- `topo_sort` is Kahn's algorithm, stable on the moon.work declaration order
- No I/O: callers read and write the files
- Depends on `moonbitlang/moon_config` (toolchain-grade parsing) + `chensuiyi/fndash`

<details>
<summary><strong>中文说明</strong></summary>

# chensuiyi/mwork

解析 `moon.work` 成员列表与 `moon.mod` 清单(name / version / imports),按依赖关系做稳定拓扑排序,重写版本行与 import pin。

- `parse_mod` 对 import 自动剥离 `@version` 后缀,得到模块路径
- `topo_sort` 为 Kahn 算法,平局保持 moon.work 声明顺序
- 无 I/O:文件读写由调用方完成
- 依赖:`moonbitlang/moon_config`(官方解析)+ `chensuiyi/fndash`

</details>

## License

MIT
