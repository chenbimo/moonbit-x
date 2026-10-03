# mwork

MoonBit 工作区清单工具库:解析 `moon.work` 成员列表与 `moon.mod` 清单(name / version / imports),按依赖关系做稳定拓扑排序,重写版本行。

```moonbit
let dirs = @mwork.parse_members(moon_work_text)      // ["bm2", "notify", ...]
let member = @mwork.parse_mod(dir, moon_mod_text)    // Member { dir, name, version, imports }
let order = @mwork.topo_sort(selected, members)      // 被依赖者先,稳定排序
@mwork.replace_version(text, "0.1.0", "0.2.0")       // 重写 version = "..." 行
```

- `parse_mod` 对 import 自动剥离 `@version` 后缀,得到模块路径
- `topo_sort` 为 Kahn 算法,平局保持 moon.work 声明顺序;环按声明序兜底追加
- 依赖:`chensuiyi/fndash`(裁剪与引号值提取),无 I/O——文件读写由调用方完成

## License

MIT
