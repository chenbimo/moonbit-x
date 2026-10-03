///|
/// Host name from the kernel, or "unknown" when it cannot be read. Used to say
/// which machine a notification came from.
pub fn hostname() -> String {
  let buf = Bytes::make(256, b'\x00')
  let len = c_hostname(buf, 256)
  if len <= 0 {
    "unknown"
  } else {
    @utf8.decode_lossy(buf[:len].to_owned())
  }
}

///|
/// The library is Linux-only. Host binaries refuse to run elsewhere with a
/// clear reason instead of failing later on the first POSIX-specific
/// syscall. Returns None when the platform is supported.
pub fn platform_error() -> String? {
  let name = try uname() catch {
    _ => return Some("cannot detect platform")
  } noraise {
    name => name
  }
  if name == "Linux" {
    None
  } else {
    Some("this build supports Linux only (detected: \{name})")
  }
}

///|
/// Close a pidfd or lock fd. Owned by the supervision layer.
pub fn close(fd : Int) -> Unit {
  ignore(c_close(fd))
}

///|
/// Ask the kernel whether `port` accepts a SO_REUSEPORT join: 0 = free
/// (nothing listening yet), 1 = joinable (listener enables reusePort),
/// 2 = held exclusively (reusePort missing), negative = errno.
pub fn probe_reuseport(port : Int) -> Int {
  c_probe_reuseport(port)
}

///|
pub fn get_uid() -> Int {
  c_getuid()
}

///|
/// Kernel name from uname(2), e.g. "Linux".
pub fn uname() -> String raise ProcessError {
  let buf = Bytes::make(64, b'\x00')
  let len = c_uname(buf, 64)
  if len < 0 {
    raise Failed(op="uname", errno=-len)
  }
  @utf8.decode_lossy(buf[:len])
}

///|
/// Absolute path of the running executable (/proc/self/exe).
pub fn self_exe() -> String raise ProcessError {
  let buf = Bytes::make(4096, b'\x00')
  let len = c_self_exe(buf, 4096)
  if len < 0 {
    raise Failed(op="self_exe", errno=-len)
  }
  @utf8.decode_lossy(buf[:len])
}

///|
/// Exit the process immediately with the given code.
pub fn exit(code : Int) -> Unit {
  c_exit(code)
}

///|
/// Write a line to stderr (for CLI diagnostics; stdout stays machine-usable).
pub fn eprintln(text : String) -> Unit {
  ignore(c_write_fd(2, @utf8.encode(text + "\n")))
}
