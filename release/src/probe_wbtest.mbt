test "probe parse_members internals" {
  let dirs = parse_members("members = [\n  \"bm2\",\n  \"notify\",\n]\n")
  println("dirs=\{dirs.length()}")
  let mut inside = false
  for line in "members = [\n  \"bm2\",\n  \"notify\",\n]\n".split("\n") {
    let t = trim_spaces(line)
    let hp = t.has_prefix("members")
    let ct = t.contains("[")
    println(
      "t=[\{t}] hp_members=\{hp} contains_bracket=\{ct} inside_before=\{inside}",
    )
    if !inside {
      if hp && ct {
        inside = true
      }
      continue
    }
    if t.has_prefix("]") {
      break
    }
  }
  println("inside_final=\{inside}")
  assert_true(inside)
}
