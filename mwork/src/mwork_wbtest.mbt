///|
/// 纯内存的拓扑排序测试:不依赖真实 workspace 布局,任何 cwd 下都可复现。
/// 真实布局的正确性由发布工具的 dry-run(e2e)覆盖。
test "topo orders dependencies before dependents" {
  let notify_member : Member = {
    dir: "notify",
    name: "chensuiyi/notify",
    version: "0.1.0",
    imports: [],
  }
  let bm2_member : Member = {
    dir: "bm2",
    name: "chensuiyi/bm2",
    version: "0.4.1",
    imports: ["chensuiyi/notify"],
  }
  let selected = [notify_member, bm2_member]
  let order = topo_sort(selected, [notify_member, bm2_member])
  assert_eq(order.length(), 2)
  assert_eq(order[0].name, "chensuiyi/notify")
  assert_eq(order[1].name, "chensuiyi/bm2")
}

///|
test "parse_members reads quoted dirs until the list closes" {
  let text =
    #|members = [
    #|  "bm2",
    #|  "notify", # trailing comment
    #|]
    #|
    #|root = "root"
  assert_eq(parse_members(text), ["bm2", "notify"])
}

///|
test "parse_mod extracts name, version and import bases" {
  let text =
    #|name = "chensuiyi/bm2"
    #|
    #|version = "0.5.0"
    #|
    #|import {
    #|  "moonbitlang/x@0.5.1",
    #|  "chensuiyi/notify@0.3.0",
    #|}
  let parsed = parse_mod("bm2", text)
  assert_eq(parsed.name, "chensuiyi/bm2")
  assert_eq(parsed.version, "0.5.0")
  assert_eq(parsed.imports, ["moonbitlang/x", "chensuiyi/notify"])
}

///|
test "parse_mod raises when name or version is absent" {
  let failed = try {
    let _ = parse_mod("broken", "license = \"MIT\"\n")
    false
  } catch {
    Missing(dir~) => dir == "broken"
  } noraise {
    _ => false
  }
  assert_true(failed)
}

///|
test "replace_version rewrites only the exact match once" {
  let text = "name = \"x\"\n\nversion = \"0.1.0\"\n\nimport {\n  \"y@0.1.0\",\n}\n"
  let next = replace_version(text, "0.1.0", "0.2.0")
  assert_true(next.contains("version = \"0.2.0\""))
  assert_false(next.contains("version = \"0.1.0\""))
  // The import pin is a different line and must survive untouched.
  assert_true(next.contains("\"y@0.1.0\""))
}

///|
test "sync_pins rewrites pinned imports in place" {
  let text =
    #|name = "x"
    #|
    #|version = "0.1.0"
    #|
    #|import {
    #|  "moonbitlang/x@0.5.1",
    #|  "chensuiyi/fndash@0.1.0",
    #|  "chensuiyi/semver@0.1.0",
    #|}
  let synced = sync_pins(text, [
    ("chensuiyi/fndash", "0.2.0"),
    ("chensuiyi/semver", "0.3.0"),
  ])
  assert_true(synced.contains("\"chensuiyi/fndash@0.2.0\""))
  assert_true(synced.contains("\"chensuiyi/semver@0.3.0\""))
  // Non-workspace imports and everything else stay untouched.
  assert_true(synced.contains("\"moonbitlang/x@0.5.1\""))
  assert_true(synced.contains("version = \"0.1.0\""))
  assert_true(synced.contains("  \"chensuiyi/fndash@0.2.0\","))
}

///|
test "sync_pins adds pins to imports lacking a version" {
  let text = "import {\n  \"chensuiyi/fndash\",\n  \"other@1.0\",\n}\n"
  let synced = sync_pins(text, [("chensuiyi/fndash", "0.9.0")])
  // An import without an @ suffix gets pinned to the given version.
  assert_true(synced.contains("\"chensuiyi/fndash@0.9.0\""))
  // Foreign modules are untouched.
  assert_true(synced.contains("\"other@1.0\""))
}
