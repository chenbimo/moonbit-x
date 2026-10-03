# chensuiyi/mwork

moon.work / moon.mod workspace toolkit · 工作区清单工具

<table>
<tr>
<th width="50%">中文</th>
<th width="50%">English</th>
</tr>
<tr>
<td valign="top">

解析 `moon.work` 成员列表与 `moon.mod` 清单(name / version / imports),按依赖关系做稳定拓扑排序,重写版本行。

- `parse_mod` 对 import 自动剥离 `@version` 后缀,得到模块路径
- `topo_sort` 为 Kahn 算法,平局保持 moon.work 声明顺序
- 无 I/O:文件读写由调用方完成
- 依赖:`chensuiyi/fndash`

</td>
<td valign="top">

Parse the `moon.work` member list and `moon.mod` manifests (name / version / imports), topologically sort members by dependencies, and rewrite version lines.

- `parse_mod` strips any `@version` suffix from imports, yielding module paths
- `topo_sort` is Kahn's algorithm, stable on the moon.work declaration order
- No I/O: callers read and write the files
- Depends on `chensuiyi/fndash`

</td>
</tr>
</table>

## API

| 接口 Interface | 说明 Description |
| --- | --- |
| `parse_members(text)` | moon.work 成员目录;Member directories from moon.work |
| `parse_mod(dir, text)` | 清单 → `Member`;Manifest → `Member` |
| `topo_sort(selected, items)` | 被依赖者先,稳定;Dependencies first, stable |
| `replace_version(text, old, next)` | 重写首个 version 行;Rewrite the first version line |

License: MIT
