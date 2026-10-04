///|
/// The `[notify]` section of bm2.toml: which events leave this project, and
/// where they go. Nothing here executes code — every string is either an
/// endpoint, a credential, or a value from a closed set that validation checks.

///|
let notifyKeys : Array[String] = [
  "enabled", "timeout_ms", "dedupe_window_s", "max_per_minute", "queue_size", "events",
  "report_interval_min", "report_fields", "daily_report_hour", "include_log_lines",
  "threshold_rss_percent", "threshold_offline_min", "threshold_restarts", "target",
]

///|
let targetKeys : Array[String] = [
  "name", "preset", "url", "secret", "format", "events", "min_level", "report", "label",
  "from", "to", "username", "password",
]

///|
/// Every platform preset bm2 can render. Keeping this a closed set is what
/// makes `preset` safe to trust: no user-supplied shape reaches the payload.
let presets : Array[String] = [
  "feishu", "dingtalk", "wecom", "slack", "discord", "webhook", "email",
]

///|
let notifyEvents : Array[String] = [
  "crash", "errored", "memory_limit", "reuseport_missing", "lifecycle", "daemon",
  "threshold", "report",
]

///|
let notifyReportFields : Array[String] = [
  "status", "rss", "cpu", "restarts", "uptime", "ports", "peak", "disk", "load",
]

///|
let notifyLevels : Array[String] = ["info", "warn", "error"]

///|
let notifyFormats : Array[String] = ["text", "markdown", "card"]

///|

///|
/// Parse the `[notify]` table of a project config. Everything here is either an
/// endpoint, a credential or a value from a closed set that validation checks;
/// nothing executes code.
pub fn parse_notify_section(
  table : Map[String, @toml.TomlValue],
) -> NotifyConfig raise ConfigError {
  reject_unknown_keys(table, notifyKeys, "notify")
  let config : NotifyConfig = {
    enabled: opt_bool(table, "enabled", "notify", false),
    timeout_ms: opt_int(table, "timeout_ms", "notify", 5000),
    dedupe_window_s: opt_int(table, "dedupe_window_s", "notify", 3600),
    max_per_minute: opt_int(table, "max_per_minute", "notify", 30),
    queue_size: opt_int(table, "queue_size", "notify", 128),
    events: opt_string_array(table, "events", "notify", []),
    report_interval_min: opt_int(table, "report_interval_min", "notify", 0),
    report_fields: opt_string_array(table, "report_fields", "notify", [
      "status", "rss", "restarts", "uptime", "ports",
    ]),
    daily_report_hour: opt_int(table, "daily_report_hour", "notify", -1),
    include_log_lines: opt_int(table, "include_log_lines", "notify", 0),
    threshold_rss_percent: opt_int(table, "threshold_rss_percent", "notify", 0),
    threshold_offline_min: opt_int(table, "threshold_offline_min", "notify", 0),
    threshold_restarts: opt_int(table, "threshold_restarts", "notify", 0),
    targets: parse_targets(table),
  }
  validate_notify(config)
  config
}

///|
fn parse_targets(
  table : Map[String, @toml.TomlValue],
) -> Array[NotifyTarget] raise ConfigError {
  match table.get("target") {
    None => []
    Some(@toml.TomlArray(items)) => {
      let targets = []
      for index, item in items {
        let ctx = "notify.target[\{index}]"
        guard item is @toml.TomlTable(fields) else {
          raise ConfigError::InvalidField("\{ctx} must be a table")
        }
        reject_unknown_keys(fields, targetKeys, ctx)
        targets.push({
          name: req_string(fields, "name", ctx),
          preset: req_string(fields, "preset", ctx),
          url: req_string(fields, "url", ctx),
          secret: opt_string_opt(fields, "secret", ctx),
          format: opt_string_opt(fields, "format", ctx),
          events: opt_string_array_opt(fields, "events", ctx),
          min_level: opt_string_opt(fields, "min_level", ctx),
          report: opt_bool_opt(fields, "report", ctx),
          label: opt_string_opt(fields, "label", ctx),
          from: opt_string_opt(fields, "from", ctx),
          to: opt_string_array_opt(fields, "to", ctx),
          username: opt_string_opt(fields, "username", ctx),
          password: opt_string_opt(fields, "password", ctx),
        })
      }
      targets
    }
    Some(_) =>
      raise ConfigError::InvalidField("target must be an array of tables")
  }
}

///|
fn opt_bool(
  table : Map[String, @toml.TomlValue],
  key : String,
  ctx : String,
  default : Bool,
) -> Bool raise ConfigError {
  match opt_bool_opt(table, key, ctx) {
    Some(value) => value
    None => default
  }
}

///|
fn opt_bool_opt(
  table : Map[String, @toml.TomlValue],
  key : String,
  ctx : String,
) -> Bool? raise ConfigError {
  match table.get(key) {
    None => None
    Some(@toml.TomlBoolean(value)) => Some(value)
    Some(_) =>
      raise ConfigError::InvalidField("\{ctx}.\{key} must be a boolean")
  }
}

///|
fn opt_string_opt(
  table : Map[String, @toml.TomlValue],
  key : String,
  ctx : String,
) -> String? raise ConfigError {
  match table.get(key) {
    None => None
    Some(@toml.TomlString(value)) => Some(value)
    Some(_) => raise ConfigError::InvalidField("\{ctx}.\{key} must be a string")
  }
}

///|
fn opt_string_array(
  table : Map[String, @toml.TomlValue],
  key : String,
  ctx : String,
  default : Array[String],
) -> Array[String] raise ConfigError {
  match opt_string_array_opt(table, key, ctx) {
    Some(value) => value
    None => default
  }
}

///|
fn opt_string_array_opt(
  table : Map[String, @toml.TomlValue],
  key : String,
  ctx : String,
) -> Array[String]? raise ConfigError {
  match table.get(key) {
    None => None
    Some(@toml.TomlArray(items)) => {
      let out = []
      for index, item in items {
        guard item is @toml.TomlString(value) else {
          raise ConfigError::InvalidField(
            "\{ctx}.\{key}[\{index}] must be a string",
          )
        }
        out.push(value)
      }
      Some(out)
    }
    Some(_) =>
      raise ConfigError::InvalidField(
        "\{ctx}.\{key} must be an array of strings",
      )
  }
}
