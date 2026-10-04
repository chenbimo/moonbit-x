# chensuiyi/subproc

Synchronous process management for MoonBit: spawn (argv / env / cwd / log redirection / own process group), waitpid and pidfd waits, process-group signals, procfs sampling (rss / cpu), and platform probes (uname / SO_REUSEPORT / self_exe). Linux native.

## Install

```bash
moon add chensuiyi/subproc
```

## API

| Interface | Description |
| --- | --- |
| `spawn(spec)` | Start a child process, return pid |
| `wait_child` / `wait_child_timeout` / `drain_child` | Reaping, with deadline-bounded and post-kill variants |
| `pidfd_open` / `pidfd_alive` / `pidfd_exited` / `wait_pidfd` | pidfd lifecycle (Linux ≥ 5.3) |
| `kill_group` / `pid_alive` / `SIGTERM` / `SIGKILL` | Signalling |
| `read_rss_kb` / `read_cpu_ticks` / `clk_tck` | procfs sampling |
| `hostname` / `uname` / `get_uid` / `self_exe` / `probe_reuseport` | Platform probes |
| `instance_env_blob` / `base_env_blob` | Environment blobs |
| `exit` / `eprintln` / `sleep_ms` / `close` | Runtime helpers |

- **pidfd**: a kernel handle pinned to one process — pid reuse never fools liveness/exit checks, adopted (non-child) processes supported
- `wait_child_timeout`: hard deadline; on expiry SIGKILLs the group and reaps with a bounded retry — a stuck helper can never freeze the caller
- `instance_env_blob`: whitelisted env plus reserved vars as a NUL blob
- Depends on `chensuiyi/fsx` and `chensuiyi/fndash`

<details>
<summary><strong>中文说明</strong></summary>

# chensuiyi/subproc

同步子进程管理:spawn(参数/env/cwd/日志重定向/独立进程组)、waitpid 与 pidfd 等待、进程组信号、procfs 采样(rss/cpu)、平台探针(uname/SO_REUSEPORT/self_exe)。Linux native。

- **pidfd**(Linux ≥ 5.3):内核句柄钉住原始进程,pid 复用不干扰存活/退出判定,支持收养非子进程
- `wait_child_timeout`:硬超时,到期 SIGKILL 整组并有界回收
- `instance_env_blob`:白名单环境 + 保留变量的 NUL blob
- 依赖:`chensuiyi/fsx`、`chensuiyi/fndash`

</details>

## License

MIT
