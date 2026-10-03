///|
/// Apply version pins to a moon.mod text: for each `(module, version)` pair,
/// every import line whose module path is `module` (with or without an
/// `@version` suffix) is rewritten to `module@version`. Indentation and any
/// trailing text after the closing quote (e.g. a comma) are preserved; lines
/// for modules not in `pins` and everything that is not an import line are
/// left untouched.
pub fn sync_pins(text : String, pins : Array[(String, String)]) -> String {
  let pin_map : Map[String, String] = Map([])
  for pair in pins {
    let (name, version) = pair
    pin_map[name] = version
  }
  let out : Array[String] = []
  for line in text.split("\n") {
    let trimmed = @fndash.trim_spaces(line)
    let mut result = line.to_owned()
    if trimmed.has_prefix("\"") && trimmed.length() > 1 {
      // Import line: the module path sits between the first quote and the
      // matching close; anything after it (typically a comma) is preserved.
      let mut stop = trimmed.length()
      for i in 1..<trimmed.length() {
        if trimmed[i].to_int() == 0x22 {
          stop = i
          break
        }
      }
      let module_path = trimmed[1:stop].to_owned()
      let mut base = module_path
      for i, ch in module_path {
        if ch == '@' {
          base = module_path[:i].to_owned()
          break
        }
      }
      match pin_map.get(base) {
        Some(version) => {
          // Keep the original line's indentation.
          let mut lead = 0
          while lead < line.length() {
            let ch = line[lead].to_int()
            if ch == 0x20 || ch == 0x09 {
              lead += 1
            } else {
              break
            }
          }
          result = line[:lead].to_owned() +
            "\"" +
            base +
            "@" +
            version +
            "\"" +
            trimmed[stop + 1:].to_owned()
        }
        None => ()
      }
    }
    out.push(result)
  }
  out.join("\n")
}
