# fsx

MoonBit 持久化文件操作库:原子写(fsync + rename + 父目录 fsync)、mkdir_p、追加、chmod、日志轮转(rotate / copytruncate)、flock、/proc 友好的小文件读取。

```moonbit
@fsx.write_atomic("state.json", data)   // 崩溃安全:tmp + fsync + 原子改名
@fsx.mkdir_p("a/b/c")                   // 幂等
@fsx.rotate("app.log")                  // 保留 10 代
let fd = @fsx.lock_exclusive("bm2.lock") // 非阻塞 flock,CLOEXEC
```

- 每一步写都由 poll 限时(5s),满盘/卡死目标不会挂住调用方
- 原子写连带 fsync 父目录,掉电后改名本身也不丢
- 运行时零依赖(仅测试使用 moonbitlang/x/fs);Linux native
- 错误统一 `FileError::Failed(op~, errno~)`,带操作名与 errno

## License

MIT
