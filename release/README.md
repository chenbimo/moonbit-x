# chensuiyi/release

moon.work 多模块发布编排工具 · Release orchestrator for moon.work workspaces

<table>
<tr>
<th width="50%">中文</th>
<th width="50%">English</th>
</tr>
<tr>
<td valign="top">

### 简介

一个仓库维护多个模块后,发布从"发一个包"变成"按依赖顺序发一串包"。这个工具把编排自动化:

1. **版本递增**——按语义化版本更新选中成员的 `moon.mod`
2. **pin 同步**——`moon work sync` 把成员版本写进依赖方的 manifest,保证发布物携带正确的依赖版本
3. **拓扑序发布**——被依赖者先发,逐个 `moon publish`,任一失败立即停止

默认发布除工具自身外的全部成员;默认 `--patch`。

</td>
<td valign="top">

### Intro

Once one repository maintains many modules, releasing stops being "publish one package" and becomes "publish a chain of packages in dependency order". This tool automates that:

1. **Version bump** — semantic version bump on the selected members' `moon.mod`
2. **Pin sync** — `moon work sync` writes member versions into dependents' manifests, so every published package carries the right dependency pins
3. **Topological publish** — dependencies first, one `moon publish` each, stopping at the first failure

By default every member except the tool itself is published; default bump is `--patch`.

</td>
</tr>
</table>

## 用法 Usage

在 workspace 根目录、WSL 中执行(工具自身会先按需构建):

Run from the workspace root in WSL (the tool rebuilds itself when needed):

```text
bash scripts/release.sh --dry-run              # 只看计划 / plan only
bash scripts/release.sh --patch                # 全成员发布 / publish all
bash scripts/release.sh --minor notify         # 只发指定成员 / one member
```

- 模块名匹配成员目录名或模块名;不带 = 全部(工具自身除外)
- 发布前提:`moon` 可用且已登录 mooncakes 账号(首次发布前 `moon login`)
- 前置质量门:发布前先跑各成员的测试(bm2 为 `bash bm2/scripts/verify.sh`)

Module names match a member directory or module name; omit them to publish everything (the tool itself excluded). `--dry-run` prints the plan only. Requires `moon` and a mooncakes login (`moon login` before the first publish). Run the quality gates first — for bm2 that is `bash bm2/scripts/verify.sh` in WSL.

## 示例 Example

```text
$ bash scripts/release.sh --dry-run
release plan (--patch):
  chensuiyi/notify 0.1.0 -> 0.1.1
  chensuiyi/bm2 0.4.1 -> 0.4.2
  moon work sync
dry-run: nothing written, nothing published
```

## 构建与运行 Build & Run

日常通过 `bash scripts/release.sh` 使用(按需自动构建);该脚本等价于:

```text
moon build --target native release
./_build/native/debug/build/chensuiyi/release/release.exe [args...]
```

`publish` 需要 `moon` 与 mooncakes 账号令牌在 WSL 的 PATH / 环境中。

## 已知问题 Known Issues

- **异常退出码恒为 0**:工具的输出(计划/错误消息)全部正确,但失败场景(`--patch --minor` 冲突、找不到 moon.work 等)进程退出码仍为 0,`&&` 链式脚本无法靠退出码判断失败。原因疑似 MoonBit async 运行时与 FFI exit 的交互,已定位到最小复现(`exit_code(N)` 不生效)。**脚本请以输出内容为准**;交互使用不受影响。

License: MIT
