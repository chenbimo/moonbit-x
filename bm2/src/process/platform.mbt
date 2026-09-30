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
/// bm2 is Linux-only. Both binaries refuse to run elsewhere with a clear
/// reason instead of failing later on the first POSIX-specific syscall.
/// Returns None when the platform is supported.
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
