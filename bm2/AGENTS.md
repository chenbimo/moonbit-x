# bm2 成员说明

Linux 下的 Bun / Node.js 进程管理器(CLI `bm2` + 守护进程 `bm2d`),moonbit 工作区成员,依赖 `chensuiyi/notify`。工作区级约定(工具链、提交格式、git hooks、WSL 注意事项)见根目录 `AGENTS.md`,本文件只写 bm2 特有的内容。

## 开发环境

- 仅 Linux(WSL Debian);要求内核 >= 5.3(pidfd)
- 所有构建 / 测试 / 验证 / 发包在 WSL 内执行;构建目录按环境隔离(WSL 脚本用 `_build-wsl`,IDE/Windows 用 `_build`)
- Windows 侧自动化调用统一走 `wsl -d Debian --cd /mnt/c/codes/moonbit/bm2 -- bash <脚本>`,复杂命令先落盘成脚本

## 统一检查入口

```bash
bash scripts/verify.sh
```

内含 `moon fmt`、`moon check --deny-warn`(含隐式提升警告)、`moon test`、`moon build` 与端到端验收(`scripts/e2e/run.sh`,需要 WSL + bun)。不要绕过入口直接调底层工具。

git hooks 由根目录统一提供(`core.hooksPath .githooks`),本成员不再有自己的钩子;提交格式与门禁规则见根 AGENTS.md。

## 版本发布两处同步

发布时同步 `moon.mod` 的 `version` 与 `src/cmd/bm2/main.mbt` 的 `VERSION` 常量(verify.sh 强制校验),再 `moon publish`。

## 代码结构

- `src/config` — bm2.toml 解析与校验(`[notify]` 订阅过滤也在此层)
- `src/core` — 实例状态机、监督循环、恢复/收养、协议、状态持久化、通知适配层(订阅过滤 + 事件日志留此,投递委托 chensuiyi/notify)
- `src/ipc` — CLI↔守护进程控制通道(长度前缀帧 + 子命令,经 loopback TCP + 共享令牌)
- `src/process` — 最小 Linux FFI(`native.c`:spawn/pidfd/procfs/exit)+ MoonBit 封装
- `src/cmd/bm2`、`src/cmd/bm2d` — CLI 与守护进程入口(参数解析用 core/argparse)

## 硬性约定

- Linux-only,不引入跨平台抽象层
- 配置不执行 shell 字符串;启动命令固定为参数数组
- 环境变量值不得写入状态文件、事件、crash 日志或 CLI 输出
- 状态文件一律原子写(经 `@process.write_atomic`)
- 通知的端点与凭据(`url`/`secret`/`username`/`password`)不得进入事件、状态、日志与 CLI 输出;校验错误只报字段名与 `target[i]` 下标(此契约同时由 chensuiyi/notify 的测试保证)
- 通知投递失败只记事件,绝不改变监督行为
- 网络能力(HTTP/SMTP)统一由 chensuiyi/notify 提供,bm2 内不自实现、不引入 curl
