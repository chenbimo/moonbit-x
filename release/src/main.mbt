///|
/// chensuiyi/release — moon.work 多模块发布编排工具。
///
/// 用法:release [--patch|--minor|--major] [--dry-run] [成员名...]
///
/// 流程:递增选中成员版本 → `moon work sync` 同步成员 pin → 按依赖拓扑序
/// 逐个 `moon publish`。在 workspace 根目录(WSL)运行。

///|
/// Communicate the outcome to the shell. `moon publish` output is already on
/// stdout/stderr; the release tool only adds its own progress lines.
extern "C" fn c_exit(code : Int) -> Unit = "bm2_release_exit"

///|
fn exit_code(code : Int) -> Unit {
  ignore(c_exit(code))
}

///|
async fn main {
  exit_code(run())
}

///|
/// This tool never publishes itself.
const SELF_MODULE : String = "chensuiyi/release"

///|
/// One workspace item: directory, module name, current version, and the
/// item modules it imports.
struct Member {
  dir : String
  name : String
  version : String
  imports : Array[String]
}

///|
suberror ReleaseError {
  MissingManifest(String)
} derive(Debug)

///|
pub extend ReleaseError with @debug.Debug::{to_repr}

///|
async fn run() -> Int {
  let cmd = @argparse.Command(
    "release",
    about="moon.work 多模块发布编排: 版本递增 → 依赖排序 → 逐个 moon publish → moon work sync",
    flags=[
      @argparse.FlagArg("patch", about="bump patch version (default)"),
      @argparse.FlagArg("minor", about="bump minor version"),
      @argparse.FlagArg("major", about="bump major version"),
      @argparse.FlagArg(
        "dry-run",
        about="print the plan without writing or publishing",
      ),
    ],
    positionals=[
      @argparse.PositionArg(
        "modules",
        about="publish only these members (default: all except this tool)",
        num_args=@argparse.ValueRange(),
      ),
    ],
  )
  let parsed = try cmd.parse(env=Map([])) catch {
    err => {
      println("\{err}")
      return 2
    }
  } noraise {
    parsed => parsed
  }
  let kind : @semver.Bump = if parsed.flags.get("major") is Some(true) {
    @semver.Bump::Major
  } else if parsed.flags.get("minor") is Some(true) {
    @semver.Bump::Minor
  } else {
    @semver.Bump::Patch
  }
  let dry_run = parsed.flags.get("dry-run") is Some(true)
  // 互斥在这里校验(工具侧),argparse 不做 flag 间冲突检测;
  // `--patch --minor` 同传时两个 flag 均为 true,在此显式拒绝。
  let kind_count = [
      parsed.flags.get("patch"),
      parsed.flags.get("minor"),
      parsed.flags.get("major"),
    ]
    .filter(fn(f) { f is Some(true) })
    .length()
  if kind_count > 1 {
    println("release: --patch/--minor/--major are mutually exclusive")
    return 2
  }
  let selectors : Array[String] = match parsed.values.get("modules") {
    Some(names) => names
    None => []
  }

  // The tool runs at the workspace root: moon.work must be there.
  let manifest = try @fs.read_file_to_string("moon.work") catch {
    _ => {
      println("release: no moon.work here; run from the workspace root")
      return 2
    }
  } noraise {
    text => text
  }
  let dirs = parse_members(manifest)
  if dirs.is_empty() {
    println("release: moon.work declares no items")
    return 2
  }
  // Read every item manifest.
  let items : Array[Member] = []
  for dir in dirs {
    let text = try @fs.read_file_to_string(dir + "/moon.mod") catch {
      _ => {
        println("release: item \{dir} has no moon.mod")
        return 2
      }
    } noraise {
      text => text
    }
    items.push(parse_mod(dir, text))
  }
  // Selection: selector names match a item directory or module name; no
  // arguments means everything except this tool itself.
  let selected : Array[Member] = []
  for item in items {
    if item.name == SELF_MODULE {
      continue
    }
    if selectors.length() == 0 {
      selected.push(item)
    } else {
      for name in selectors {
        if name == item.dir || name == item.name {
          selected.push(item)
          break
        }
      }
    }
  }
  if selected.length() == 0 {
    println("release: nothing selected")
    return 2
  }
  // Publish order: dependencies of selected items first (Kahn, stable by
  // workspace item order).
  let order = topo_sort(selected, items)
  let mode = match kind {
    @semver.Bump::Patch => "--patch"
    @semver.Bump::Minor => "--minor"
    @semver.Bump::Major => "--major"
  }
  println("release plan (\{mode}):")
  for item in order {
    println(
      "  \{item.name} \{item.version} -> \{@semver.bump(@semver.parse(item.version), kind).to_string()}",
    )
  }
  println("  moon work sync")
  if dry_run {
    println("dry-run: nothing written, nothing published")
    return 0
  }
  // 1. Bump versions on disk.
  for item in order {
    let next = @semver.bump(@semver.parse(item.version), kind).to_string()
    let text = try @fs.read_file_to_string(item.dir + "/moon.mod") catch {
      _ => ""
    } noraise {
      text => text
    }
    try
      @fs.write_string_to_file(
        item.dir + "/moon.mod",
        replace_version(text, item.version, next),
      )
    catch {
      _ => {
        println("release: cannot write \{item.dir}/moon.mod")
        return 1
      }
    } noraise {
      _ => ()
    }
    println("bumped \{item.name}: \{item.version} -> \{next}")
  }
  // 2. Sync item pins to the new versions before anything is published, so
  // every published manifest already carries the right pins.
  let sync = try
    @process.collect_output("moon", ["work", "sync"], cwd=".")
  catch {
    e => {
      println("release: moon work sync failed: \{e}")
      return 1
    }
  } noraise {
    output => output
  }
  if sync.0 != 0 {
    println("release: moon work sync exited \{sync.0}")
    println(@utf8.decode_lossy(sync.2.binary()))
    return 1
  }
  println("synced item dependency versions")
  // 3. Publish dependencies first.
  for item in order {
    println("publishing \{item.name} ...")
    let result = try
      @process.collect_output("moon", ["publish"], cwd=item.dir)
    catch {
      e => {
        println("release: cannot run moon publish for \{item.name}: \{e}")
        return 1
      }
    } noraise {
      output => output
    }
    if result.0 != 0 {
      println("release: \{item.name} publish failed (exit \{result.0})")
      println(@utf8.decode_lossy(result.2.binary()))
      return 1
    }
    println("published \{item.name}")
  }
  println("release complete")
  0
}

///|
/// Directory names from the `items` list of moon.work.
fn parse_members(text : String) -> Array[String] {
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
    // A item line looks like `"bm2",` — keep the quoted part.
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
fn parse_mod(dir : String, text : String) -> Member raise {
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
    raise ReleaseError::MissingManifest(dir)
  }
  { dir, name, version, imports, }
}

///|
/// Order selected items so that a item never publishes before a selected
/// item it imports. Stable: ties keep the moon.work item order.
fn topo_sort(selected : Array[Member], items : Array[Member]) -> Array[Member] {
  // Member name → item, for import resolution.
  let by_name : Map[String, Member] = Map([])
  for item in items {
    by_name[item.name] = item
  }
  let selected_names : Map[String, Unit] = Map([])
  for item in selected {
    selected_names[item.name] = ()
  }
  // Kahn's algorithm over the selected subgraph.
  let deps : Map[String, Int] = Map([])
  let dependents : Map[String, Array[String]] = Map([])
  for item in selected {
    deps[item.name] = 0
    dependents[item.name] = []
  }
  for item in selected {
    for imported in item.imports {
      match by_name.get(imported) {
        Some(target) =>
          if selected_names.contains(target.name) {
            // item imports target: target publishes first.
            let current = match deps.get(item.name) {
              Some(count) => count
              None => 0
            }
            deps[item.name] = current + 1
            dependents[target.name].push(item.name)
          }
        None => ()
      }
    }
  }
  let order : Array[Member] = []
  let ready : Array[String] = []
  for item in selected {
    let count = match deps.get(item.name) {
      Some(count) => count
      None => 0
    }
    if count == 0 {
      ready.push(item.name)
    }
  }
  while ready.length() > 0 {
    let name = ready.remove(0)
    for item in selected {
      if item.name == name {
        order.push(item)
        break
      }
    }
    match dependents.get(name) {
      Some(list) =>
        for dependent in list {
          let rest = match deps.get(dependent) {
            Some(count) => count - 1
            None => 0
          }
          deps[dependent] = rest
          if rest == 0 {
            ready.push(dependent)
          }
        }
      None => ()
    }
  }
  // Cycles cannot happen between real modules; append leftovers defensively.
  for item in selected {
    let mut found = false
    for done in order {
      if done.name == item.name {
        found = true
        break
      }
    }
    if !found {
      order.push(item)
    }
  }
  order
}

///|
/// Replace `version = "old"` with `version = "next"` in a moon.mod text.
fn replace_version(text : String, old : String, next : String) -> String {
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

