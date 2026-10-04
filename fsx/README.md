# chensuiyi/fsx

Durable file operations for MoonBit: atomic write (fsync + rename + parent-dir fsync), `mkdir_p`, append, chmod, log rotation (rename / copytruncate), flock, and /proc-friendly small reads. Linux native.

## Install

```bash
moon add chensuiyi/fsx
```

## Features

- Atomic write: `.tmp` → fsync → rename, parent directory fsynced as well
- Every write step is bounded by a poll deadline (5s) — a full disk or a stalled target never hangs the caller
- Log rotation in two modes: rename (self-written logs) and copytruncate (fd-held logs)
- Non-blocking flock with CLOEXEC — spawned children never inherit the lock
- Idempotent `mkdir_p`; uniform `FileError::Failed(op~, errno~)` errors
- Zero runtime dependencies

## Scenarios

- Daemon state files that must survive power loss
- Singleton locks for long-running processes
- Reading /proc virtual files (`/proc/<pid>/status`, `environ`, `cmdline`)

## API

| Function | Description |
| --- | --- |
| `write_atomic(path, data)` | Write `.tmp` → fsync → atomic rename; parent dir fsynced |
| `mkdir_p(path, mode?)` | Idempotent recursive mkdir |
| `append_file(path, data)` | Poll-bounded append |
| `chmod(path, mode)` | Tighten mode of an existing path |
| `unlink(path)` | Remove |
| `file_size(path)` | Size in bytes, `None` when missing |
| `rotate(path)` | Shift chain, rename to `.1`, drop `.10` |
| `copytruncate(path)` | Copy to `.1`, truncate in place |
| `lock_exclusive(path)` | Non-blocking flock, returns fd |
| `read_small(path, cap?)` | Read to EOF, capped |

<details>
<summary><strong>用法示例 / usage</strong></summary>

```moonbit
// Crash-safe state write
@fsx.mkdir_p("/var/lib/myapp")
@fsx.write_atomic("/var/lib/myapp/state.json", b"{\"pid\":42}")

// Singleton lock
let lock_fd = @fsx.lock_exclusive("/var/run/myapp.lock")

// /proc read
let cmdline = @fsx.read_small("/proc/self/cmdline")
```

</details>

## Author

**陈随易** ([@chenbimo](https://github.com/chenbimo)) · [mooncakes: chensuiyi](https://mooncakes.io/user/chensuiyi)

## License

MIT

<details>
<summary><strong>中文文档</strong></summary>

# chensuiyi/fsx

MoonBit 持久化文件操作:原子写(fsync + rename + 父目录 fsync)、`mkdir_p`、追加、chmod、日志轮转(rename / copytruncate 双模式)、flock、/proc 友好的小文件读取。Linux native。

## 安装

```bash
moon add chensuiyi/fsx
```

## 功能

- 原子写:`.tmp` → fsync → 原子改名,父目录一并 fsync
- 每一步写都由 poll 限时(5s),满盘/卡死目标不会挂住调用方
- 日志轮转双模式:rename(自写日志)/ copytruncate(进程持有 fd)
- 非阻塞 flock 且 CLOEXEC——子进程不继承锁
- `mkdir_p` 幂等;错误统一 `FileError::Failed(op~, errno~)`
- 运行时零依赖

## 场景

- 守护进程状态文件:掉电后不丢、不半截
- 长驻进程单实例锁
- 读取 /proc 虚拟文件(`/proc/<pid>/status`、`environ`、`cmdline`)

## API

| 函数 | 说明 |
| --- | --- |
| `write_atomic(path, data)` | 写 `.tmp` → fsync → 原子改名;父目录一并 fsync |
| `mkdir_p(path, mode?)` | 幂等递归建目录 |
| `append_file(path, data)` | poll 限时追加 |
| `chmod(path, mode)` | 收紧已有路径权限 |
| `unlink(path)` | 删除 |
| `file_size(path)` | 字节大小,不存在返回 `None` |
| `rotate(path)` | 链条平移,改名 `.1`,丢弃 `.10` |
| `copytruncate(path)` | 复制到 `.1`,原地截断 |
| `lock_exclusive(path)` | 非阻塞 flock,返回 fd |
| `read_small(path, cap?)` | 读到 EOF,受 cap 限制 |

## 用法示例

```moonbit
// 掉电安全的状态写入
@fsx.mkdir_p("/var/lib/myapp")
@fsx.write_atomic("/var/lib/myapp/state.json", b"{\"pid\":42}")

// 单实例锁
let lock_fd = @fsx.lock_exclusive("/var/run/myapp.lock")

// /proc 读取
let cmdline = @fsx.read_small("/proc/self/cmdline")
```

## 作者

**陈随易** ([@chenbimo](https://github.com/chenbimo)) · [mooncakes: chensuiyi](https://mooncakes.io/user/chensuiyi)

## 协议

MIT

</details>
