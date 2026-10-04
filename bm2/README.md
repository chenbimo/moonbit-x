# bm2

`bm2` 是一个现代化的 Bun 与 Node.js 进程管理器，基于 MoonBit 编程语言实现。

bm2 由命令行工具和后台守护进程组成，命令行通过本机 TCP + 共享令牌下达指令，守护进程持续托管应用进程。

每个用户一个独立守护进程，可同时管理多个项目。

托管能力包括多实例、崩溃自动重启、内存限制、优雅停止与状态持久化。

反向代理与负载均衡交给 Nginx、Caddy 之类的网关负责，bm2 只专注进程托管。

英文文档：[README.en.md](README.en.md)

## bm2与pm2对比

| 对比项           | bm2                                               | pm2                                    |
| ---------------- | ------------------------------------------------- | -------------------------------------- |
| 形态             | 原生静态二进制                                    | Node.js 应用                           |
| 额外依赖         | 无                                                | Node.js 运行时                         |
| 体积             | 约 `5.5 MB`（两个二进制）                         | 约 `23 MB`                             |
| 文件数量         | `2` 个                                            | `3036` 个                              |
| 空闲守护进程内存 | 约 `2.6 MB`                                       | 约 `50 MB`                             |
| 命令响应         | 约 `1 ms`                                         | 约 `200~400 ms`                        |
| 日志轮转         | 内置，`10 MB × 10 代`                             | 需额外安装 `pm2-logrotate` 模块        |
| 多实例模式       | `fork` 连续端口 + `cluster` 单端口（内核分发）    | `fork` + `cluster`（master 分发）      |
| cluster 分发层   | 内核 `SO_REUSEPORT`，无中间层、无单点             | cluster master 进程，宕机即整应用中断  |
| 守护进程崩溃     | 应用无感继续运行，新守护进程原地收养              | cluster 应用随之中断，恢复需重建进程树 |
| 配置方式         | 静态 TOML，字段强校验，零代码执行                 | `ecosystem.config.js`，可执行任意代码  |
| 环境变量         | 最小白名单 + 保留变量显式注入                     | 继承调用 shell 的完整环境              |
| 崩溃恢复         | pidfd 钉住原进程收养，环境校验防误管              | 守护进程崩溃后按 dump 重建，不收养     |
| 自升级           | `bm2 upgrade`：比对版本、安装、自动换入新守护进程 | npm 手动升级后 `pm2 update` 重载       |

## 功能特性

**进程托管**

- 一个 `bm2.toml` 配置**一个项目**（单个应用，一个或多个独立实例，上限 1024）。
- 命令：`start`、`kill`、`list`、`reload`、`upgrade`、`version`、`notify`。
- 优雅停止：SIGTERM 宽限期后 SIGKILL；`start` 总是对其项目执行一次完整重启。

**监督与自愈**

- 崩溃自动重启：异常退出按 `restart_delay_ms` 延迟重启，spawn 失败按次数递增退避。
- 崩溃预算 `max_restarts`：连续异常重启超预算即进入 `errored`，停止自愈等待人工介入。
- 干净退出（超 min_uptime 的 code 0）不消耗崩溃预算，按计划重启。
- 内存限制 `max_memory_mb`：超限按异常重启处理。

**集群与负载均衡**

- cluster 模式基于 `SO_REUSEPORT`：所有实例共享一个端口，内核分发，无中间层、无单点。
- fork 模式连续端口，交给 Nginx / Caddy 分发。
- 启动后实测 reusePort，缺失即停止整个项目并明确报错。

**可靠性与状态**

- pidfd 进程跟踪：守护进程崩溃后新守护进程原地收养应用，应用无感继续运行。
- 状态持久化：掉电、崩溃后实例状态不丢、不半截（原子写 + fsync）。
- 本机 TCP + 共享令牌控制通道，令牌常量时间比较，敏感目录 0700。
- CLI 与守护进程互相校验协议版本。

**日志**

- stdout / stderr / crash 诊断三路分离，严格区别于 bm2 自身管理日志。
- 按 10 MB 轮转，保留十代；事件日志 JSONL，不含任何敏感数据。

**通知与上报**

- 七平台预设（飞书/钉钉/企业微信/Slack/Discord/webhook/邮件），按项目独立配置。
- 覆盖崩溃、预算耗尽、内存超限、reusePort 缺失、生命周期、阈值告警、定期体检。
- 去重、限流、队列、退避重试内置；凭据零泄露。

**自升级**

- `bm2 upgrade` 比对版本、安装新二进制并自动换入新守护进程，应用继续运行。

它不管理 Nginx、域名、证书、热重载、开机自启或远程管理。

## 环境要求

- 仅支持 Linux，非 Linux 构建会拒绝运行并给出明确提示。
- 需要 Linux 内核 >= 5.3（pidfd 进程跟踪）。
- [MoonBit](https://www.moonbitlang.com/)（仅安装/升级 bm2 时需要）
- [Bun](https://bun.sh/)，版本 >= 1.4.0
- [Node.js](https://nodejs.org/)，版本 >= 24.0.0（仅 `runtime = "node"` 的项目需要）

`bm2 start` 会实测运行时版本，低于下限时拒绝启动并给出具体版本提示。

守护进程的 `PATH` 在其启动时定格：安装新的运行时后，先执行 `bm2 reload` 换入新守护进程再启动项目。

## 安装与升级

先安装 MoonBit 工具链：

```bash
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
```

再安装 bm2：

```bash
moon install chensuiyi/bm2/...
```

bm2 默认安装到 moon 工具链所在的 `~/.moon/bin`，无需任何 `PATH` 配置。

`bm2` 与 `bm2d` 两个二进制一起安装。

两者都必须留在 `PATH` 中，因为 `bm2` 通过名字启动 `bm2d`。

升级到 mooncakes 上的最新版本，装完自动换入新守护进程：

```bash
bm2 upgrade          # 比对版本、执行 moon install，并自动换入新守护进程
```

## 配置参数

在你运行 `bm2` 的目录创建 `bm2.toml`。

以下为完整模板，包含全部字段与默认值，直接复制修改即可：

```toml
# 项目名：字母开头，后接字母、数字和下划线。
# 同时也是应用名，在所有已注册项目中必须唯一。
name = "api"

# 应用工作目录（绝对路径），默认为 bm2.toml 所在目录。
cwd = "/srv/api"

# 相对 cwd 的脚本路径，禁止 .. 段。
script = "src/index.ts"

# 运行时：bun 或 node。
runtime = "bun"

# 执行模式：cluster（默认，所有实例共享同一个 port，由内核分发
# 连接，应用监听需开启 reusePort）或 fork（端口从 port 起连续分配）。
exec_mode = "cluster"

# 实例数量（1..1024）。
instances = 2
port = 3000

# 单实例内存上限（MiB），超过按异常重启处理，至少为 1。
max_memory_mb = 512

# 连续异常重启预算，0 表示首次异常即 errored。
max_restarts = 10

# 自动重启前的延迟（毫秒），崩溃后固定，spawn 失败后按次数递增。
restart_delay_ms = 1000

# 干净退出早于此时长（毫秒）会计入重启预算。
min_uptime_ms = 10000

# SIGTERM 到 SIGKILL 的宽限期（毫秒），最大 60000。
stop_timeout_ms = 10000
```

默认（cluster）所有实例共享同一个 `port`；`exec_mode = "fork"` 时端口从 `port` 起连续分配（`port + 实例编号`）。

所有已注册项目的端口范围不得重叠（cluster 项目只占一个端口槽），冲突时 bm2 拒绝启动。

从 0.3.0 升级注意：`exec_mode` 是 0.4.0 新增字段且默认 cluster。多实例项目若应用未在监听时开启 `reusePort`，升级后要么显式声明 `exec_mode = "fork"` 保持旧行为，要么给应用监听加上 `reusePort` 后享用 cluster（未开启时第二个实例会因端口占用崩溃）。

## 环境变量

`bm2.toml` 的 `[env]` 表为应用注入自定义环境变量(值必须为字符串)，写在项目根表之后：

```toml
[env]
MYSQL_HOST = "127.0.0.1"
MYSQL_PORT = "3306"
```

注入顺序:白名单环境 → `[env]` → 保留变量(最后，不可被覆盖)。bun/node 的 `.env` 文件不会覆盖已存在的环境变量，因此 `[env]` 的值优先于项目自带的 env 文件。

除此之外，bm2 只把自己的 `PATH`、`HOME`、`TMPDIR` 传给被管理进程，外加这些保留变量：

- `BM2_APP_NAME`（项目名）
- `BM2_INSTANCE_ID`（实例编号，第一个实例为 `"0"`）
- `BM2_APP_INSTANCE`（同实例编号，命名对齐 PM2 的 `NODE_APP_INSTANCE` 习惯）
- `BM2_APP_PORT`（分配给该实例的端口：默认（cluster）恒为 `port`，fork 模式等于 `port` 加实例编号）
- `NODE_ENV`（恒为 `"production"`）

cluster 模式（默认）下所有实例拿到同一个端口（如 `3000`），由内核分发连接；fork 模式下端口与实例编号一一对应：`BM2_APP_PORT = port + BM2_APP_INSTANCE`，例如 `port = 3000` 且 `instances = 3` 时，三个实例分别监听 `3000`、`3001`、`3002`。

应用内典型用法：

- 用 `BM2_APP_PORT` 绑定监听端口，多实例各占一个端口。
- 用 `BM2_APP_INSTANCE === "0"` 判断主实例，只在主实例执行数据库迁移、定时任务等一次性逻辑。
- 用 `NODE_ENV === "production"` 走生产分支。

```js
const PORT = Number(process.env.BM2_APP_PORT ?? 3000);
const isPrimary = process.env.BM2_APP_INSTANCE === "0";

Bun.serve({ port: PORT, fetch: () => new Response("ok") });

if (isPrimary) {
  // 只在主实例执行：数据库迁移、定时任务等
}
```

应用自身的环境变量由应用与运行时自行加载，bm2 不解析 `.env`，也不参与加载。

bm2 已注入的变量不会被运行时的 `.env` 加载覆盖。

## 命令使用

```bash
bm2 start             # 注册/更新当前目录中的项目并启动它
bm2 kill <name>       # 停止一个项目并注销它；bm2d 继续运行
bm2 kill -y           # 停止所有项目、注销它们并退出 bm2d（裸 `kill` 会拒绝执行）
bm2 list [name]       # 显示所有已注册项目的状态;--json 输出机器可读 JSON
bm2 reload            # 换入新的 bm2d；被管理的应用继续运行
bm2 upgrade           # 把 bm2 升级到 mooncakes 上的最新版本
bm2 version           # 显示 bm2 版本
```

`start` 和 `kill <name>` 是异步的：守护进程立即应答，CLI 轮询直到操作完成，因此守护进程永远不会因停止超时而阻塞。

`bm2 list`、`bm2 kill`、`bm2 reload` 和 `bm2 version` 可以在任意目录执行。

只有 `bm2 start` 必须在包含 `bm2.toml` 的目录中运行，因为它要从该配置注册项目。

裸 `bm2 kill`（不带 `-y`）时 bm2 拒绝执行并打印提示。

在项目中（或在另一个使用相同 `name` 的目录中）重新运行 `bm2 start` 会更新配置并执行完整重启，因此修改任何字段——包括实例数量、端口或脚本——都会在下一次 start 时生效。

被 kill 的项目（`bm2 kill <name>`）会完全注销：它从 `bm2 list` 中消失，且不会因守护进程重启而复现。注销只删除项目的注册信息，`~/.bm2/<name>/` 下的实例状态与日志会保留，便于事后排查。

对 bm2d 发送 SIGTERM（例如 systemd 执行 `systemctl restart`）与 `bm2 kill -y` 走同一条路径：停止所有项目、注销它们并退出。只有 `bm2 reload` 会在换入新守护进程时保留注册与被托管的实例。

`reload` 在不停止被管理应用的情况下换入新的 bm2d：旧守护进程分离，新守护进程以不变的 PID 收养仍在运行的实例。

手动替换二进制后使用，`bm2 upgrade` 会自动执行这一步。CLI 与守护进程会互相校验协议版本，版本不一致时直接提示执行 `bm2 reload`，而不是给出难以定位的错误。

`list` 为每个活跃或异常实例打印一行，包括 PID、端口、执行模式（cluster/fork）、运行状态、内存、运行时长，以及最后一列 `CWD` 中的完整项目工作目录。

被有意停止的实例会被省略，`restarting` 和 `errored` 实例保持可见，便于运维诊断。

如果守护进程意外崩溃并留下过期的控制端点文件，下一个 CLI 请求会短暂等待响应、删除过期文件、启动一个新的守护进程，并重试一次请求。

## 负载均衡

默认的 cluster 模式下，所有实例共享同一个端口：

```toml
# exec_mode 可省略，默认即 cluster
instances = 4
port = 3000
```

cluster 模式基于 Linux `SO_REUSEPORT`：每个实例监听同一个端口，内核按连接四元组哈希分发，无需网关即可实现单端口多副本负载均衡（需要 bun >= 1.4.0 或 node >= 24.0.0）。

应用侧监听时打开 `reusePort`：

```js
const PORT = Number(process.env.BM2_APP_PORT);

// Bun
Bun.serve({ port: PORT, reusePort: true, fetch: () => new Response("ok") });

// Node.js
const http = require("node:http");
http.createServer((req, res) => res.end("ok")).listen({ port: PORT, reusePort: true });
```

实例崩溃重启后重新加入端口组，其余实例不受影响；`BM2_APP_INSTANCE === "0"` 的主实例判断在 cluster 模式下同样可用。

bm2 会在启动后探测监听是否真的开启了 `reusePort`：未开启时整个项目被停止，所有实例进入 `errored`（原因 `reuseport_missing`），修正应用后重新 `bm2 start` 即可，注册不会丢失。

需要域名、TLS 或跨机分发时仍配合网关使用，cluster 项目只需一条 `server 127.0.0.1:3000;`。

fork 模式则用连续端口交给网关做负载均衡。

bm2 只专注进程托管，反向代理与负载均衡交给 Nginx、Caddy 之类的网关。

网关把域名指向实例的连续端口即可，实例增减后同步更新 upstream 列表并 reload 网关。

Nginx 示例（假设 `instances = 2`，`port = 3000`）：

```nginx
upstream bm2_app {
    server 127.0.0.1:3000;
    server 127.0.0.1:3001;
}

server {
    listen 80;
    server_name example.com;

    location / {
        proxy_pass http://bm2_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Caddy 示例：

```caddyfile
example.com {
    reverse_proxy 127.0.0.1:3000 127.0.0.1:3001
}
```

## 状态与日志

bm2 总是把 socket、PID、状态和管理日志存放在当前 Linux 用户的 `~/.bm2` 下（`HOME` 不可用时回退到 `/tmp/bm2-<uid>`）。

每个用户一个守护进程，管理所有已注册项目：

```text
daemon.port                      # 控制通道端口（本机 TCP）
daemon.token                     # 控制通道共享令牌，0700 目录内
bm2d.pid                         # 守护进程 PID
bm2.events.jsonl                 # CLI 连接与重试事件
bm2d.log                         # 守护进程 stderr / 运行时诊断
bm2d.events.jsonl                # 守护进程与监督事件
<name>/project.json              # 每个项目的注册信息（配置路径）
<name>/<name>-<id>.json          # 持久化的实例状态
<name>/logs/<name>-<id>.out.log    # 应用 stdout
<name>/logs/<name>-<id>.error.log  # 应用 stderr
<name>/logs/<name>-<id>.crash.log  # 异常退出诊断
```

日志按大小轮转：每个文件达到 10 MB 时轮转，保留十代（`.1` .. `.10`，每个文件最多约 100 MB）。

应用日志与 bm2 自身的管理日志严格分离。

两个 `*.events.jsonl` 文件每行一个 JSON 对象。

它们只记录管理元数据：时间戳、事件名、适用时的应用/实例/PID、运维原因。

它们**不**包含环境变量值、协议载荷或应用输出。

常用命令：

```bash
tail -f ~/.bm2/bm2d.events.jsonl
jq -c . ~/.bm2/bm2d.events.jsonl
```

## 通知与上报

bm2 可以把运行情况上报出去：崩溃与自动恢复、崩溃预算耗尽、内存超限、cluster 模式缺少 reusePort、启动/停止/注销等生命周期动作，以及定时的运行体检与阈值告警。

通知配置属于**项目**，写在同一个 `bm2.toml` 里的 `[notify]` 与 `[[notify.target]]`；改动在下一次 `bm2 start` 时生效。项目自己只上报自己的事件，收件人也是自己配置的那些目标。

投递由内置实现（`moonbitlang/async` + `chensuiyi/notify`，含 HTTPS 与 SMTP），不依赖 `curl` 等外部命令。

```bash
bm2 notify            # 在项目目录执行，给该项目所有目标发一条测试消息
bm2 notify <name>     # 只发给指定目标
```

### 配置字段

`[notify]` 全部可选，不写这段即完全不上报：

| 字段 | 含义 | 示例 |
| --- | --- | --- |
| `enabled` | 总开关，默认 `false` | `true` |
| `timeout_ms` | 单条投递硬超时（100~60000，默认 5000），同时也是监督循环被占用的上限 | `5000` |
| `dedupe_window_s` | 同一事件签名的最小重复间隔（0~604800，默认 3600），0 表示不去重 | `3600` |
| `max_per_minute` | 发送上限（0~6000，默认 30），超限丢弃并计数；0 表示不限 | `30` |
| `queue_size` | 该项目待发队列上限（1~4096，默认 128），满则丢最新事件并计数 | `128` |
| `events` | 订阅的事件名，取值见事件表，未知值直接拒绝；默认空 | `["crash","errored"]` |
| `report_interval_min` | 定期体检间隔（0~10080 分钟，默认 0 即关闭；最小 1 即每分钟一次） | `60` |
| `report_fields` | 体检包含的字段：`status`/`rss`/`cpu`/`restarts`/`uptime`/`ports`/`peak`（窗口 RSS 峰值）/`disk`（状态目录所在盘剩余）/`load`（系统 1 分钟负载） | `["status","rss"]` |
| `daily_report_hour` | 每日定点日报的小时（0~23，默认 -1 即关闭），内容同体检并附带自上一份日报以来的 RSS 峰值 | `8` |
| `include_log_lines` | 崩溃通知附带 crash.log 末尾行数（0~50）；日志可能含敏感信息，默认 0 | `0` |
| `threshold_rss_percent` | RSS 达到内存上限的百分比时告警（0~100，默认 0 即关闭） | `80` |
| `threshold_offline_min` | 实例离开 online 超过该分钟数告警（0~1440，默认 0 即关闭） | `5` |
| `threshold_restarts` | 连续异常重启达到该次数时告警（0~1000，默认 0 即关闭） | `5` |
| `start_timeout_ms` | spawn 后超过该毫秒数端口仍未监听则告警（0~600000，默认 0 即关闭） | `30000` |
| `threshold_disk_mb` | `~/.bm2` 所在文件系统剩余空间低于该 MB 数时告警（0~1048576，默认 0 即关闭） | `1024` |
| `threshold_storm` | 10 分钟窗口内重启（含 spawn 失败重试）达到该次数时告警（0~1000，默认 0 即关闭） | `20` |

### 凭据字段支持环境变量

`url`、`secret`、`username`、`password`、`from` 五个字段支持 `${VAR}` 形式的环境变量引用，因此 bm2.toml 可以只带占位符提交到仓库，真实端点与密钥留在环境里：

```toml
[[notify.target]]
name = "feishu-test"
preset = "feishu"
url = "${BM2_TEST_WEBHOOK_URL}"
secret = "${BM2_TEST_SIGN_KEY}"
```

- 变量未设置时解析直接报错并指名变量名，绝不会静默替换成空值。
- 环境以「解析配置的进程」为准：`bm2 start` / `bm2 notify` 用 shell 当前环境，托管期上报用守护进程的环境——守护进程环境在其启动时定格，改动环境变量后先 `bm2 reload` 换入新守护进程再 `bm2 start`。
- 守护进程继承的是最小环境（`PATH`/`HOME`/`TMPDIR`），外加全部 `BM2_` 开头的变量——凭据变量以此命名空间命名即可穿透到守护进程。
- 其余字段（script、port 等）不做环境变量展开，只有通知凭据需要它。

每个目标写在 `[[notify.target]]` 里：

| 字段 | 含义 |
| --- | --- |
| `name` | 目标名，必须唯一；日志与失败提示里只出现它，不出现端点与凭据 |
| `preset` | 平台预设，见平台表 |
| `url` | 端点；web 平台为 `http://` 或 `https://`，邮件为 `smtp://` 或 `smtps://` |
| `secret` | 平台要求的密钥/令牌/签名密钥（敏感） |
| `username` | 仅邮件使用：SMTP 用户名 |
| `password` | 仅邮件使用 |
| `from` / `to` | 仅邮件使用；`to` 是数组，可多个收件人 |
| `format` | `text` / `markdown` / `card`；预设不支持时按自身能力降级 |
| `events` | 覆盖全局订阅 |
| `min_level` | `info` / `warn` / `error`，低于该级别不发送 |
| `report` | 该目标是否接收定期体检，默认接收 |
| `label` | 可选，消息里的环境标识 |

凭据只存在于 `bm2.toml` 与守护进程内存，永远不会出现在事件日志、状态文件、crash 日志、CLI 输出或 `ps` 里；校验错误只报字段与目标下标。

### 平台预设

| preset | 平台 | `url` | `secret` / `username` |
| --- | --- | --- | --- |
| `feishu` | 飞书 / Lark 自定义机器人 | webhook 地址 | `secret` 可选（签名密钥） |
| `dingtalk` | 钉钉群机器人 | webhook 地址 | `secret` 可选（加签密钥） |
| `wecom` | 企业微信群机器人 | webhook 地址 | — |
| `slack` | Slack incoming webhook（兼容 Matrix / Zulip / Mattermost / Rocket.Chat） | webhook 地址 | — |
| `discord` | Discord webhook | webhook 地址 | — |
| `webhook` | 任意自建/其他平台 | 任意 http(s) 地址 | `secret` 可选（Bearer） |
| `email` | SMTP / SMTPS | `smtps://smtp.example.com:465` | `username` + `password` |

没有内置预设的平台走 `webhook`：它发送固定形状的 JSON（`event`/`level`/`title`/`body`/`host`/`timestamp`/`fields`），自建网关或函数把它转成任何平台的格式都行。飞书、钉钉、企业微信的“HTTP 200 + 响应体错误码”会被解析，非零错误码按投递失败处理。

### 事件与体检

| 事件 | 说明 |
| --- | --- |
| `crash` | 异常退出或启动失败，尚未耗尽预算，会退避重试 |
| `errored` | 崩溃预算耗尽，已停止自动恢复，需要人工介入 |
| `memory_limit` | RSS 超过上限，按异常重启处理 |
| `reuseport_missing` | cluster 项目未开启 reusePort，整个项目被停止 |
| `lifecycle` | 项目启动 / 停止 / 注销，以及干净退出后的自动重新拉起 |
| `daemon` | 守护进程启动或 reload 换入后，本项目已被接管 |
| `threshold` | 内存接近上限、实例长时间未恢复、重启过频、重启风暴（10 分钟窗口，`threshold_storm`） |
| `oom_kill` | SIGKILL 且最后采样 RSS 达上限 90% 以上，判定为内核 OOM killer；其余 SIGKILL 仍归 `crash` |
| `disk_pressure` | 状态目录所在文件系统剩余空间低于 `threshold_disk_mb` |
| `start_timeout` | spawn 后 `start_timeout_ms` 内端口始终无人监听，应用可能卡在 bind 之前 |
| `report` | 定期体检 |

崩溃类通知会指认原因：cluster 项目崩溃时若检测到端口被其他进程独占，正文会注明端口冲突；SIGKILL 且内存逼近上限会以 `oom_kill` 单独上报。控制通道的每次握手失败（错误令牌或端口探测）都会写入 `bm2d.events.jsonl` 的 `auth_failed` 事件。

体检内容取决于 `report_fields`：实例状态、RSS、CPU 百分比（需要两次采样，守护进程重启后的首次不显示）、连续异常次数、运行时长、端口，以及窗口峰值 `peak`（自上一份报告以来该实例 RSS 的最高水位，采样随内存检查每轮进行，报告后清零）、磁盘 `disk`（`~/.bm2` 所在文件系统的剩余空间）与系统负载 `load`（1 分钟 load average，守护进程级，每份一条）。`report_interval_min` 最小为 1，即每分钟一次体检；阈值与体检共用每分钟一次的评估节拍。

`daily_report_hour` 在体检之外提供每日定点日报：到点发一份标题为 daily report 的报告，实例行携带自上一份日报以来的 RSS 峰值（独立于体检峰值窗口），同一自然日只发一次。

### 上报行为

- **按项目隔离**：每个项目只上报自己的事件，收件人只来自自己的 `[notify.target]`；一个项目没配 `[notify]` 就完全不上报，互不影响。
- **去重**：`事件 + 应用 + 实例 + 原因` 作为签名，`dedupe_window_s` 内只发第一条，其余累加；窗口过期后再发时会在正文里注明上一个窗口的累计次数。填 `86400` 即为“同一签名每天一条”。
- **限流与有序丢弃**：每分钟上限之外的条目被丢弃并计数；队列满时丢的是最新事件，保留突发里最早、通常也是根因的那几条。
- **重试**：只有“所有目标都没收到”才重试（5s、15s，最多 3 次）；只要有一个目标成功就不再重试，避免对已收到的目标重复打扰。
- **发送失败不影响托管**：失败只写 `~/.bm2/bm2d.events.jsonl`（`notify_failed`、`notify_target_failed`、`notify_rate_limited` 等），进程监督照常进行。
- 飞书、钉钉、企业微信的应答是“HTTP 200 + 响应体错误码”，bm2 会解析它：非零错误码视为投递失败并记入事件日志，`code`/`errcode` 为 0 才算成功。

配置示例（写在项目的 `bm2.toml` 末尾）：

```toml
name = "api"
script = "src/index.ts"
instances = 2
port = 3000

[notify]
enabled = true
events = ["crash", "errored", "memory_limit", "reuseport_missing"]
report_interval_min = 60
threshold_rss_percent = 80

[[notify.target]]
name = "飞书-运维群"
preset = "feishu"
url = "https://open.feishu.cn/open-apis/bot/v2/hook/xxxx"
min_level = "warn"

[[notify.target]]
name = "值班邮件"
preset = "email"
url = "smtps://smtp.example.com:465"
from = "bm2@example.com"
to = ["ops@example.com", "oncall@example.com"]
username = "bm2@example.com"
password = "xxxx"
min_level = "error"
```
