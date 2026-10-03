# subproc

MoonBit 同步进程管理库:spawn(env/cwd/日志重定向/独立进程组)、waitpid 与 pidfd 等待、进程组信号、procfs 采样(rss/cpu)、平台探针。Linux native。

```moonbit
let pid = @subproc.spawn({
  bun_path: "bun", script: "app.js", cwd: dir,
  out_log: "o.log", err_log: "e.log",
  env_blob: @subproc.base_env_blob(),
})
@subproc.kill_group(pid, @subproc.SIGTERM)
let reaped = @subproc.wait_child_timeout(pid, timeout_ms=5000)
```

- **pidfd**(Linux ≥ 5.3):内核句柄钉住原始进程,pid 复用不会骗过存活/退出判定,支持收养(非子)进程
- `wait_child_timeout`:硬超时,到期 SIGKILL 整个进程组并有界回收,卡死的辅助进程永远不会冻结单线程守护进程
- `instance_env_blob`:白名单环境 + 保留变量(后写不可覆盖)的 NUL blob
- 平台探针:uname/platform_error、SO_REUSEPORT 探测、/proc/self/exe
- 依赖 `chensuiyi/fsx`(测试与文档示例中的文件操作)

## License

MIT
