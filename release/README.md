# chensuiyi/release

moon.work multi-module release orchestration: bump versions → dependency order → pin sync → `moon publish` per member. Run from the workspace root in WSL.

## Usage

Daily driver is `bash scripts/release.sh` (rebuilds the tool when needed). Equivalent direct form:

```text
moon build --target native release
./_build/native/debug/build/chensuiyi/release/release.exe [args...]
```

```text
bash scripts/release.sh --dry-run              # plan only
bash scripts/release.sh --patch                # publish all members
bash scripts/release.sh --minor notify         # publish one member
```

- Member names match a member directory or module name; omit them to publish everything (the tool itself excluded)
- `--dry-run` prints the plan only — nothing written, nothing published
- Requires `moon` on PATH and a mooncakes login (`moon login` before the first publish)
- Run the quality gates first — for bm2 that is `bash bm2/scripts/verify.sh` in WSL

## How it works

1. **Version bump** — semantic version bump on the selected members' `moon.mod`
2. **Pin sync** — import pins in every member's manifest are rewritten to the new versions (self-implemented via `mwork.sync_pins`; no `moon work sync` subprocess)
3. **Topological publish** — dependencies first, one `moon publish` each, stopping at the first failure

By default every member except the tool itself is published; default bump is `--patch`.

<details>
<summary><strong>中文说明</strong></summary>

# chensuiyi/release

moon.work 多模块发布编排工具。

流程:递增选中成员版本 → 自实现 pin 同步(把新版本写进依赖方 manifest,替代 `moon work sync` 子进程)→ 按依赖拓扑序逐个 `moon publish`。任一失败立即停止。

- 默认发布除工具自身外的全部成员;默认 `--patch`
- 在 workspace 根目录、WSL 中执行;`--dry-run` 只打印计划
- 前置质量门:发布前先跑各成员测试(bm2 为 `bash bm2/scripts/verify.sh`)
- 需要 `moon` 与 mooncakes 账号令牌(首次发布前 `moon login`)

</details>

## Author

**陈随易** ([@chenbimo](https://github.com/chenbimo)) · [mooncakes: chensuiyi](https://mooncakes.io/user/chensuiyi)

## License

MIT
