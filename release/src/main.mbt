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
  let dirs = @mwork.parse_members(manifest)
  if dirs.is_empty() {
    println("release: moon.work declares no items")
    return 2
  }
  // Read every item manifest.
  let items : Array[@mwork.Member] = []
  for dir in dirs {
    let text = try @fs.read_file_to_string(dir + "/moon.mod") catch {
      _ => {
        println("release: item \{dir} has no moon.mod")
        return 2
      }
    } noraise {
      text => text
    }
    items.push(@mwork.parse_mod(dir, text))
  }
  // Selection: selector names match a item directory or module name; no
  // arguments means everything except this tool itself.
  let selected : Array[@mwork.Member] = []
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
  let order = @mwork.topo_sort(selected, items)
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
        @mwork.replace_version(text, item.version, next),
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

