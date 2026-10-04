///|
pub(all) suberror ProcessError {
  Failed(op~ : String, errno~ : Int)
}

///|
pub impl Show for ProcessError with fn output(self, logger) {
  match self {
    Failed(op~, errno~) => {
      logger.write_string(op)
      logger.write_string(" failed: errno ")
      logger.write_string(errno.to_string())
    }
  }
}

///|
pub extend ProcessError with Show::{to_string, output}

///|
fn cstr(s : String) -> Bytes {
  @utf8.encode(s + "\u{0}")
}

///|
#borrow(bun_path, script, cwd, out_path, err_path, env_blob)
extern "C" fn c_spawn(
  bun_path : Bytes,
  script : Bytes,
  cwd : Bytes,
  out_path : Bytes,
  err_path : Bytes,
  env_blob : Bytes,
) -> Int = "subproc_spawn"

///|
#borrow(out)
extern "C" fn c_waitpid(pid : Int, nohang : Int, out : Bytes) -> Int = "subproc_waitpid"

///|
extern "C" fn c_kill_pg(pgid : Int, sig : Int) -> Int = "subproc_kill_pg"

///|
extern "C" fn c_kill0(pid : Int) -> Int = "subproc_kill0"

///|
extern "C" fn c_sleep_ms(ms : Int) -> Unit = "subproc_sleep_ms"

///|
extern "C" fn c_getpid() -> Int = "subproc_getpid"

///|
extern "C" fn c_read_rss_kb(pid : Int) -> Int = "subproc_read_rss_kb"

///|
extern "C" fn c_read_cpu_ticks(pid : Int) -> Int64 = "subproc_read_cpu_ticks"

///|
extern "C" fn c_clk_tck() -> Int = "subproc_clk_tck"

///|
#borrow(buf)
extern "C" fn c_hostname(buf : Bytes, cap : Int) -> Int = "subproc_hostname"

///|
extern "C" fn c_close(fd : Int) -> Int = "subproc_close"

///|
/// Probe a port's SO_REUSEPORT status by binding: 0 = free (not listening
/// yet), 1 = joinable (the listener shares, reusePort on), 2 = held
/// exclusively (reusePort missing), negative = errno.
extern "C" fn c_probe_reuseport(port : Int) -> Int = "subproc_probe_reuseport"

///|
extern "C" fn c_getuid() -> Int = "subproc_getuid"

///|
#borrow(buf)
extern "C" fn c_uname(buf : Bytes, cap : Int) -> Int = "subproc_uname"

///|
extern "C" fn c_pidfd_open(pid : Int) -> Int = "subproc_pidfd_open"

///|
#borrow(out)
extern "C" fn c_wait_pidfd(fd : Int, nohang : Int, out : Bytes) -> Int = "subproc_wait_pidfd"

///|
extern "C" fn c_pidfd_alive(fd : Int) -> Int = "subproc_pidfd_alive"

///|
#borrow(buf)
extern "C" fn c_self_exe(buf : Bytes, cap : Int) -> Int = "subproc_self_exe"

///|
extern "C" fn c_exit(code : Int) -> Unit = "subproc_exit"

///|
extern "C" fn c_load_1m() -> Double = "subproc_load_1m"

///|
#borrow(path)
extern "C" fn c_disk_free_kb(path : Bytes) -> Int64 = "subproc_disk_free_kb"

///|
#borrow(data)
extern "C" fn c_write_fd(fd : Int, data : Bytes) -> Int = "subproc_write_fd"
