///|
/// Replace `version = "old"` with `version = "next"` in a moon.mod text.
/// Only the first exact-match line is rewritten; the caller reads and
/// writes the file.
pub fn replace_version(text : String, old : String, next : String) -> String {
  let target = "version = \"" + old + "\""
  let replacement = "version = \"" + next + "\""
  let lines = text.split("\n")
  let out : Array[String] = []
  let mut done = false
  for line in lines {
    if !done && @fndash.trim_spaces(line) == target {
      out.push(replacement)
      done = true
    } else {
      out.push(line.to_owned())
    }
  }
  out.join("\n")
}
