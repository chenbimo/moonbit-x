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
fn obj_get(ast : @moon_config.Ast, key : String) -> @moon_config.Ast? {
  match ast {
    Obj(fields, ..) =>
      for pair in fields {
        let (k, v) = pair
        if k == key {
          return Some(v)
        }
      }
    _ => ()
  }
  None
}

///|
fn ast_str(ast : @moon_config.Ast, key : String) -> String? {
  match obj_get(ast, key) {
    Some(Str(s, ..)) => Some(s)
    _ => None
  }
}

///|
fn ast_str_or(
  ast : @moon_config.Ast,
  key : String,
  fallback : String,
) -> String {
  match ast_str(ast, key) {
    Some(s) => s
    None => fallback
  }
}

///|
/// Directory names from the `members` list of moon.work, parsed with
/// moonbitlang/moon_config (toolchain-grade parsing).
pub fn parse_members(text : String) -> Array[String] {
  let (ast, _reports) = @moon_config.parse_moon_work(text)
  let dirs : Array[String] = []
  match obj_get(ast, "members") {
    Some(Arr(items, ..)) =>
      for item in items {
        match item {
          Str(s, ..) => dirs.push(s)
          _ => ()
        }
      }
    _ => ()
  }
  dirs
}

///|

///|
/// Parse one moon.mod text: module name, version and the module paths in
/// the import list (any @version suffix stripped). Raises Missing when
/// name or version cannot be found.
pub fn parse_mod(dir : String, text : String) -> Member raise ManifestError {
  let (ast, _reports) = @moon_config.parse_moon_mod(text)
  let name = ast_str_or(ast, "name", "")
  let version = ast_str_or(ast, "version", "")
  let imports : Array[String] = []
  // moon_config post-processes the import list into a "deps" object:
  // { "moonbitlang/x": "0.5.1", ... } — the keys are the module paths
  // (already @version-stripped).
  match obj_get(ast, "deps") {
    Some(Obj(fields, ..)) =>
      for pair in fields {
        let (module_path, _version) = pair
        imports.push(module_path)
      }
    _ => ()
  }
  if name == "" || version == "" {
    raise Missing(dir~)
  }
  { dir, name, version, imports, }
}
