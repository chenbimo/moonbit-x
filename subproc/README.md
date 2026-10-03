# chensuiyi/subproc

Synchronous process management · 同步进程管理

<table>
<tr>
<th width="50%">中文</th>
<th width="50%">English</th>
</tr>
<tr>
<td valign="top">

同步子进程管理:spawn(参数/env/cwd/日志重定向/独立进程组)、waitpid 与 pidfd 等待、进程组信号、procfs 采样(rss/cpu)、平台探针(uname/SO_REUSEPORT/self_exe)。

- **pidfd**(Linux ≥ 5.3):内核句柄钉住原始进程,pid 复用不干扰存活/退出判定,支持收养非子进程
- `wait_child_timeout`:硬超时,到期 SIGKILL 整组并有界回收
- `instance_env_blob`:白名单环境 + 保留变量的 NUL blob
- 依赖:`chensuiyi/fsx`、`chensuiyi/fndash`

</td>
<td valign="top">

Synchronous child-process management: spawn (argv/env/cwd/log redirection/own process group), waitpid and pidfd waits, process-group signals, procfs sampling (rss/cpu), platform probes (uname/SO_REUSEPORT/self_exe).

- **pidfd** (Linux ≥ 5.3): a kernel handle pinned to one process — pid reuse never fools liveness/exit checks, and adopted (non-child) processes are supported
- `wait_child_timeout`: hard deadline; on expiry SIGKILLs the group and reaps with a bounded retry
- `instance_env_blob`: whitelisted env plus reserved vars as a NUL blob
- Depends on `chensuiyi/fsx` and `chensuiyi/fndash`

</td>
</tr>
</table>

## API

| 接口 Interface | 说明 Description |
| --- | --- |
| `spawn(spec)` | 启动子进程返回 pid;Spawn a child, return pid |
| `wait_child` / `wait_child_timeout` / `drain_child` | 回收;Reaping, deadline-bounded variants |
| `pidfd_open` / `pidfd_alive` / `pidfd_exited` / `wait_pidfd` | pidfd 生命周期;pidfd lifecycle |
| `kill_group` / `pid_alive` / `SIGTERM` / `SIGKILL` | 信号;Signalling |
| `read_rss_kb` / `read_cpu_ticks` / `clk_tck` | procfs 采样;procfs sampling |
| `hostname` / `uname` / `get_uid` / `self_exe` / `probe_reuseport` | 平台探针;Platform probes |
| `instance_env_blob` / `base_env_blob` | 环境 blob;Environment blobs |
| `exit` / `eprintln` / `sleep_ms` / `close` | 运行辅助;Runtime helpers |

License: MIT
