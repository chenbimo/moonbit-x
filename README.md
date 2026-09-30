# moonbit

MoonBit 生态库集群 · A cluster of MoonBit ecosystem libraries

<table>
<tr>
<th width="50%">中文</th>
<th width="50%">English</th>
</tr>
<tr>
<td valign="top">

### 简介

基于 `moon.work` 的多模块工作区:一个仓库维护多个模块,成员之间本地引用、无需发布即可联调。

用到什么造什么:每个库一个目录,持续沉淀为可独立发布的 MoonBit 模块。

### 成员

- [bm2](bm2/README.md) — Linux 下的 Bun / Node.js 进程管理器

新库在仓库根目录 `moon new` 创建后,把模块名加入 `moon.work` 的 `members` 即可。

### 布局

<pre>
moonbit/
├── moon.work              # 工作区成员列表
├── bm2/                   # chensuiyi/bm2
└── README.md
</pre>

### 工具链

- MoonBit `moonc 0.10.14`(IDE / WSL / CI 统一)
- bm2 在 WSL 中验证:`bash bm2/scripts/verify.sh`

</td>
<td valign="top">

### Intro

A multi-module workspace built on `moon.work`: one repository maintains many modules; members reference each other locally and can be developed together without publishing.

Build what you need, when you need it: one directory per library, growing into independently publishable MoonBit modules.

### Members

- [bm2](bm2/README.md) — a process manager for Bun / Node.js on Linux

To add a library, create it with `moon new` at the repository root and append the module name to `members` in `moon.work`.

### Layout

<pre>
moonbit/
├── moon.work              # workspace members
├── bm2/                   # chensuiyi/bm2
└── README.md
</pre>

### Toolchain

- MoonBit `moonc 0.10.14` (identical across IDE, WSL and CI)
- bm2 is verified in WSL: `bash bm2/scripts/verify.sh`

</td>
</tr>
</table>
