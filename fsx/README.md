# chensuiyi/fsx

Durable file operations · 持久化文件操作

<table>
<tr>
<th width="50%">中文</th>
<th width="50%">English</th>
</tr>
<tr>
<td valign="top">

崩溃安全的文件写入与目录操作:原子写(fsync + rename + 父目录 fsync)、mkdir_p、追加、chmod、日志轮转(rename 与 copytruncate 双模式)、flock、/proc 友好的小文件读取。

- 每一步写都由 poll 限时(5s),满盘/卡死目标不会挂住调用方
- `mkdir_p` 幂等;错误统一 `FileError::Failed(op~, errno~)`
- 运行时零依赖;Linux native

</td>
<td valign="top">

Crash-safe file writing and directory operations: atomic write (fsync + rename + parent-dir fsync), mkdir_p, append, chmod, log rotation (rename and copytruncate modes), flock, /proc-friendly small reads.

- Every write step is bounded by a poll deadline (5s) — a full disk or a stalled target never hangs the caller
- `mkdir_p` is idempotent; errors are `FileError::Failed(op~, errno~)`
- Zero runtime dependencies; Linux native

</td>
</tr>
</table>

## API

| 接口 Interface | 说明 Description |
| --- | --- |
| `write_atomic(path, data)` | 写 `.tmp` → fsync → 原子改名;Atomic write via tmp + fsync + rename |
| `mkdir_p(path, mode?)` | 幂等建目录;Idempotent recursive mkdir |
| `append_file` / `chmod` / `unlink` / `file_size` | 追加 / 改权限 / 删除 / 大小;Append / chmod / remove / size |
| `rotate` / `copytruncate` | 轮转(保留 10 代);Rotation, ten generations kept |
| `lock_exclusive(path)` | 非阻塞 flock(CLOEXEC);Non-blocking flock, CLOEXEC |
| `read_small(path, cap?)` | 循环读到 EOF 或 cap;Read to EOF, capped |

License: MIT
