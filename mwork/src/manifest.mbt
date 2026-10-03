///|
/// One workspace member: directory, module name, current version, and the
/// member modules it imports.
pub(all) struct Member {
  dir : String
  name : String
  version : String
  imports : Array[String]
}

///|
pub(all) suberror ManifestError {
  Missing(dir~ : String)
}

///|
pub impl Show for ManifestError with fn output(self, logger) {
  match self {
    Missing(dir~) => {
      logger.write_string("manifest is missing name or version: ")
      logger.write_string(dir)
    }
  }
}

///|
pub extend ManifestError with Show::{to_string, output}

///|
/// Directory names from the `members` list of moon.work.
pub fn parse_members(text : String) -> Array[String] {
  let dirs = []
  let mut inside = false
  for line in text.split("\n") {
    let trimmed = @fndash.trim_spaces(line)
    if !inside {
      if trimmed.has_prefix("members") && trimmed.contains("[") {
        inside = true
      }
      continue
    }
    if trimmed.has_prefix("]") || trimmed.has_prefix("#") {
      break
    }
    // A member line looks like `"bm2",` — keep the quoted part.
    let bytes = @utf8.encode(trimmed)
    let mut start = -1
    for i, byte in bytes {
      if byte.to_int() == 0x22 && start < 0 {
        start = i
      } else if byte.to_int() == 0x22 && start >= 0 {
        dirs.push(trimmed[start + 1:i].to_owned())
        break
      }
    }
  }
  dirs
}

///|
/// Parse one moon.mod text: module name, version and the module paths in
/// the import list (any @version suffix stripped). Raises Missing when
/// name or version cannot be found.
pub fn parse_mod(dir : String, text : String) -> Member raise ManifestError {
  let mut name = ""
  let mut version = ""
  let imports : Array[String] = []
  let mut in_imports = false
  for line in text.split("\n") {
    let trimmed = @fndash.trim_spaces(line)
    if trimmed.has_prefix("import") {
      in_imports = true
      continue
    }
    if in_imports {
      if trimmed.has_prefix("\"") {
        // An import line: strip the surrounding quotes and any @version
        // suffix. The line starts with the opening quote at index 0, so the
        // scan for the closing one starts at 1.
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
        imports.push(base)
        continue
      }
      if trimmed.has_prefix("}") {
        in_imports = false
      }
      continue
    }
    if trimmed.has_prefix("name") && trimmed.contains("=") {
      name = @fndash.quoted_value(trimmed)
    } else if trimmed.has_prefix("version") && trimmed.contains("=") {
      version = @fndash.quoted_value(trimmed)
    }
  }
  if name == "" || version == "" {
    raise Missing(dir~)
  }
  { dir, name, version, imports, }
}
