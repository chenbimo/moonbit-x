# chensuiyi/fsx

Durable file operations for MoonBit: atomic write (fsync + rename + parent-dir fsync), `mkdir_p`, append, chmod, log rotation (rename / copytruncate), flock, /proc-friendly small reads. Linux native.

## Install

```bash
moon add chensuiyi/fsx
```

## API

| Interface | Description |
| --- | --- |
| `write_atomic(path, data)` | Write `.tmp` → fsync → atomic rename; parent dir fsynced too |
| `mkdir_p(path, mode?)` | Idempotent recursive mkdir |
| `append_file` / `chmod` / `unlink` / `file_size` | Append / tighten mode / remove / size |
| `rotate` / `copytruncate` | Log rotation, ten generations kept |
| `lock_exclusive(path)` | Non-blocking flock (CLOEXEC), returns fd |
| `read_small(path, cap?)` | Read to EOF, capped — works on /proc virtual files |

Every write step is bounded by a poll deadline (5s) — a full disk or a stalled target never hangs the caller. Errors are `FileError::Failed(op~, errno~)`.

<details>
<summary><strong>中文说明</strong></summary>

# chensuiyi/fsx

持久化文件操作:原子写(fsync + rename + 父目录 fsync)、`mkdir_p`、追加、chmod、日志轮转(rename / copytruncate 双模式)、flock、/proc 友好的小文件读取。Linux native。

## API

| 接口 | 说明 |
| --- | --- |
| `write_atomic(path, data)` | 写 `.tmp` → fsync → 原子改名;父目录一并 fsync |
| `mkdir_p(path, mode?)` | 幂等递归建目录 |
| `append_file` / `chmod` / `unlink` / `file_size` | 追加 / 收紧权限 / 删除 / 大小 |
| `rotate` / `copytruncate` | 轮转(保留 10 代)/ 原地截断复制 |
| `lock_exclusive(path)` | 非阻塞 flock(CLOEXEC),返回 fd |
| `read_small(path, cap?)` | 循环读到 EOF 或 cap,可用于 /proc 虚拟文件 |

- 每一步写都由 poll 限时(5s),满盘/卡死目标不会挂住调用方
- 错误统一 `FileError::Failed(op~, errno~)`,带操作名与 errno
- 运行时零依赖

</details>

## License

MIT
