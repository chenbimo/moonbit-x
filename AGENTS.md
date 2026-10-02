# moonbit 工作区约定

`moon.work` 单仓库多模块,当前成员:`bm2` / `notify` / `release`(见根目录 `moon.work`)。

## 工具链

- MoonBit `moonc 0.10.14`,IDE / WSL / CI 三处统一
- **操作环境:除用 IDE 写代码外,构建 / 测试 / 验证 / 发包全部在 WSL 执行**(Windows 侧不装工具链、不发包)
- **构建目录两级制(大仓根)**:`_build` = Windows IDE 默认产物;`_build-wsl` = WSL 全部构建的显式目标(`--target-dir _build-wsl`,moon.work 模式下全 workspace 产物整体落在该树)。成员目录内不落任何构建产物
- **WSL 互操作层不可信(已实证)**:本机 wsl.exe 的参数桥会随机损坏输出与退出码回传——同一二进制,interop 通道测得恒 0,文件通道测得真实码(2/1/0)。因此:复杂命令一律落盘脚本后以 `wsl bash 脚本` 执行;涉及退出码 / 输出内容的验证,**结果必须写文件再读回**,禁止依赖命令行回传;出现"异常退出码"类怪象时,先用文件通道复测再定位
- 验证:bm2 在 WSL 中执行 `bash bm2/scripts/verify.sh`;各成员的验证方式见各自文档
- 发包:WSL 中 `bash scripts/release.sh`(首次发包前在 WSL `moon login` 登录 mooncakes)
- 平台:bm2 仅 Linux;新增成员若含平台相关 C 桩,必须在本文档标注

## 提交格式(严格遵守)

仓库为单仓多项目,**每个提交必须标注所属项目**。格式:

```text
[项目名](类型) 提交内容
```

- **项目名**:成员目录名——`bm2` / `notify` / `release`;根级文件(`moon.work`、`README.md`、本文件)用 `root`
- **类型**:`feat` / `fix` / `docs` / `refactor` / `test` / `chore`
- **提交内容**:一句话说明,中文,结尾不加句号

示例:

```text
[bm2](feat) 新增 reload 命令
[notify](fix) 限流窗口按 owner 独立
[release](feat) 支持 --dry-run
[root](docs) 补充工作区约定
```

规则:

1. 一个提交只属于一个项目;跨项目的改动拆成多个提交,**被依赖者先提交**
2. 缺括号、缺类型、项目名不存在的提交不允许入仓
3. 新增成员后,项目名 = 成员目录名,本规则自动适用
4. Merge / Revert 提交豁免(git 生成首行,格式不适用)

提交格式由 `commit-msg` 钩子强制校验(见下节)。

## Git Hooks(全仓库统一)

钩子位于根目录 `.githooks/`,跨环境分发:git 在 Windows 驱动时自动把检查交给 WSL 执行。

激活(仓库初始化后执行一次):

```bash
git init
git config core.hooksPath .githooks
```

| 钩子 | 时机 | 做什么 |
| --- | --- | --- |
| `commit-msg` | 提交时 | 强制校验上文提交格式,不合规则的提交被拒绝 |
| `pre-commit` | 提交时 | 只检查本次改动涉及的成员:`moon fmt` 自动修复并重新暂存 + `moon check --deny-warn`;bm2 另校验版本号一致 |
| `pre-push` | 推送时 | 全成员完整验证:bm2 `verify.sh`(单测/构建/e2e)、notify 检查+单测、release 检查+构建 |

- 只提交根级文件时,pre-commit 自动跳过成员检查
- 确需绕过:`git commit --no-verify`(例外应 rare)
- 钩子实现:`scripts/hook-dispatch.sh`(跨环境分发)+ `scripts/{pre-commit,commit-msg,pre-push}.sh` + `scripts/lib/common.sh`(成员注册表;新增成员在此登记检查命令)
