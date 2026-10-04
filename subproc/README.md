# chensuiyi/subproc

Synchronous process management for MoonBit: spawn (argv / env / cwd / log redirection / own process group), waitpid and pidfd waits, process-group signals, procfs sampling (rss / cpu), and platform probes (uname / SO_REUSEPORT / self_exe). Linux native.

<details>
<summary><strong>中文文档</strong></summary>

## 简介

同步子进程管理:spawn(参数 / env / cwd / 日志重定向 / 独立进程组)、waitpid 与 pidfd 等待、进程组信号、procfs 采样(rss / cpu)、平台探针(uname / SO_REUSEPORT / self_exe)。Linux native。

## 功能

- **pidfd**(Linux ≥ 5.3):内核句柄钉住原始进程,pid 复用不干扰存活/退出判定
- `wait_child_timeout`:硬超时,到期 SIGKILL 整组并有界回收
- `instance_env_blob`:白名单环境 + 保留变量的 NUL blob

## 场景

- 进程监督器:拉起、回收、崩溃预算、内存采样
- 构建工具:运行测试 / 编译器并限时收尸
- 平台探针:启动前检查 OS / 端口复用能力

</details>

## Features

- **pidfd** (Linux ≥ 5.3): a kernel handle pinned to one process — pid reuse never fools liveness/exit checks, adopted (non-child) processes supported
- `wait_child_timeout`: hard deadline; on expiry SIGKILLs the group and reaps with a bounded retry — a stuck helper can never freeze the caller
- `instance_env_blob`: whitelisted env plus reserved vars as a NUL blob
- procfs sampling: VmRSS and utime+stime per process
- Platform probes: uname, SO_REUSEPORT bind test, `/proc/self/exe`, uid
- Own process group per child (setsid), stdout/stderr redirection to log files

## Scenarios

- Process supervisors: spawn, reap, crash budgets, memory sampling
- Build tools and dev CLIs: run tests / compilers with hard timeouts
- Adopted-process tracking: exit detection that survives pid reuse

## API

| Function | Description |
| --- | --- |
| `spawn(spec)` | Start a child, return pid |
| `wait_child(pid, nohang?)` | Reap via waitpid |
| `wait_child_timeout(pid, timeout_ms)` | Deadline-bounded reap with group SIGKILL |
| `wait_pidfd(fd, nohang?)` | Reap via waitid(P_PIDFD) |
| `drain_child(pid)` | Bounded reap of a just-killed child |
| `pidfd_open` / `pidfd_alive` / `pidfd_exited` | pidfd lifecycle |
| `kill_group(pgid, sig)` / `pid_alive(pid)` | Signals |
| `read_rss_kb(pid)` / `read_cpu_ticks(pid)` / `clk_tck()` | procfs sampling |
| `hostname` / `uname` / `get_uid` / `self_exe` / `probe_reuseport` | Platform probes |
| `instance_env_blob` / `base_env_blob` | Environment blobs |
| `exit` / `eprintln` / `sleep_ms` / `close` | Runtime helpers |

<details>
<summary><strong>用法示例 / usage</strong></summary>

```moonbit
// Spawn with log redirection and own process group
let pid = @subproc.spawn({
  bun_path: "bun",
  script: "app.js",
  cwd: "/srv/app",
  out_log: "/var/log/app.out.log",
  err_log: "/var/log/app.err.log",
  env_blob: @subproc.instance_env_blob("app", 0, 3000),
})

// Graceful stop with hard deadline
@subproc.kill_group(pid, @subproc.SIGTERM)
let reaped = @subproc.wait_child_timeout(pid, 5000)

// Sample
let rss = @subproc.read_rss_kb(pid)
```

</details>

## Author

**陈随易** ([@chenbimo](https://github.com/chenbimo)) · [mooncakes: chensuiyi](https://mooncakes.io/user/chensuiyi)

## License

MIT
