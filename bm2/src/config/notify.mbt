///|
/// The `[notify]` section of a project config: which events leave this
/// project, where they go, and on what schedule. Nothing here executes
/// code — every string is either an endpoint, a credential, or a value from
/// a closed set that validation checks. `${VAR}` expansion already happened
/// at the tree level before any of this runs.

///|
let notifyKeys : Array[String] = [
  "enabled", "lang", "timeout_ms", "dedupe_window_s", "max_per_minute", "queue_size",
  "events", "threshold_rss_percent", "threshold_offline_min", "threshold_restarts",
  "start_timeout_ms", "threshold_disk_mb", "threshold_storm", "mail_url", "mail_from",
  "mail_username", "mail_password", "target",
]

///|
/// Routing fields plus the seven platform objects. Exactly one platform
/// object per target.
let targetKeys : Array[String] = [
  "name", "label", "events", "min_level", "interval", "content", "feishu", "dingtalk",
  "wecom", "slack", "discord", "webhook", "email",
]

///|
/// Every platform bm2 can render. Keeping this a closed set is what makes
/// the platform object key safe to trust: no user-supplied shape reaches
/// the payload.
let platforms : Array[String] = [
  "feishu", "dingtalk", "wecom", "slack", "discord", "webhook", "email",
]

///|
let notifyEvents : Array[String] = [
  "crash", "errored", "memory_limit", "reuseport_missing", "lifecycle", "daemon",
  "threshold", "oom_kill", "disk_pressure", "start_timeout",
]

///|
let notifyLevels : Array[String] = ["info", "warn", "error"]

///|
let notifyFormats : Array[String] = ["text", "markdown", "card"]

///|
/// Preset report contents for periodic targets. The set grows over time;
/// the shape of the table does not.
let notifyContents : Array[String] = ["health", "stats"]

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
/// Parse the `[notify]` table of a project config.
pub fn parse_notify_section(
  table : Map[String, @toml.TomlValue],
) -> NotifyConfig raise ConfigError {
  reject_unknown_keys(table, notifyKeys, "notify")
  let config : NotifyConfig = {
    enabled: opt_bool(table, "enabled", "notify", false),
    lang: opt_lang(table),
    timeout_ms: opt_int(table, "timeout_ms", "notify", 5000),
    dedupe_window_s: opt_int(table, "dedupe_window_s", "notify", 3600),
    max_per_minute: opt_int(table, "max_per_minute", "notify", 30),
    queue_size: opt_int(table, "queue_size", "notify", 128),
    events: opt_string_array(table, "events", "notify", []),
    threshold_rss_percent: opt_int(table, "threshold_rss_percent", "notify", 0),
    threshold_offline_min: opt_int(table, "threshold_offline_min", "notify", 0),
    threshold_restarts: opt_int(table, "threshold_restarts", "notify", 0),
    start_timeout_ms: opt_int(table, "start_timeout_ms", "notify", 0),
    threshold_disk_mb: opt_int(table, "threshold_disk_mb", "notify", 0),
    threshold_storm: opt_int(table, "threshold_storm", "notify", 0),
    mail_url: opt_string_opt(table, "mail_url", "notify"),
    mail_from: opt_string_opt(table, "mail_from", "notify"),
    mail_username: opt_string_opt(table, "mail_username", "notify"),
    mail_password: opt_string_opt(table, "mail_password", "notify"),
    targets: parse_targets(table),
  }
  validate_notify(config)
  config
}

///|
/// Notification copy language, a closed set: "en" (default) or "zh".
fn opt_lang(table : Map[String, @toml.TomlValue]) -> String raise ConfigError {
  match opt_string_opt(table, "lang", "notify") {
    Some(value) =>
      if value == "en" || value == "zh" {
        value
      } else {
        raise ConfigError::InvalidField(
          "notify.lang has unknown value \{value}",
        )
      }
    None => "en"
  }
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
        // Exactly one platform object per target: its key names the platform
        // and its table carries the connection config.
        let mut found = ""
        for platform in platforms {
          if fields.contains(platform) {
            if found != "" {
              raise ConfigError::InvalidField(
                "\{ctx} has two platform objects (\{found}, \{platform}); one target is one platform",
              )
            }
            found = platform
          }
        }
        if found == "" {
          raise ConfigError::InvalidField(
            "\{ctx} must configure exactly one platform object",
          )
        }
        let interval = match opt_string_opt(fields, "interval", ctx) {
          Some(text) => Some(parse_interval(text, ctx))
          None => None
        }
        let content = opt_string_opt(fields, "content", ctx)
        // interval and content are a pair; events routing is event-target
        // only.
        if interval is Some(_) && content is None {
          raise ConfigError::InvalidField(
            "\{ctx}.interval requires content (health / stats)",
          )
        }
        if interval is None && content is Some(_) {
          raise ConfigError::InvalidField("\{ctx}.content requires interval")
        }
        match content {
          Some(value) =>
            if !notifyContents.contains(value) {
              raise ConfigError::InvalidField(
                "\{ctx}.content has unknown value \{value}",
              )
            }
          None => ()
        }
        if interval is Some(_) {
          if fields.contains("events") {
            raise ConfigError::InvalidField(
              "\{ctx}.events is not used by a periodic target",
            )
          }
          if fields.contains("min_level") {
            raise ConfigError::InvalidField(
              "\{ctx}.min_level is not used by a periodic target",
            )
          }
        }
        // The platform object itself.
        guard fields.get(found) is Some(@toml.TomlTable(platform_table)) else {
          raise ConfigError::InvalidField("\{ctx}.\{found} must be a table")
        }
        let platform_keys : Array[String] = ["url", "secret", "format", "to"]
        reject_unknown_keys(platform_table, platform_keys, "\{ctx}.\{found}")
        let mail_to = match platform_table.get("to") {
          None => None
          Some(@toml.TomlArray(items)) => {
            let recipients = []
            for recipient in items {
              guard recipient is @toml.TomlString(text) else {
                raise ConfigError::InvalidField(
                  "\{ctx}.\{found}.to must be strings",
                )
              }
              recipients.push(text)
            }
            Some(recipients)
          }
          Some(_) =>
            raise ConfigError::InvalidField(
              "\{ctx}.\{found}.to must be an array",
            )
        }
        targets.push({
          name: req_string(fields, "name", ctx),
          label: opt_string_opt(fields, "label", ctx),
          events: opt_string_array_opt(fields, "events", ctx),
          min_level: opt_string_opt(fields, "min_level", ctx),
          interval,
          content,
          platform: found,
          url: if found == "email" {
            ""
          } else {
            req_string(platform_table, "url", ctx)
          },
          secret: opt_string_opt(platform_table, "secret", ctx),
          format: opt_string_opt(platform_table, "format", ctx),
          mail_to,
        })
      }
      targets
    }
    Some(_) =>
      raise ConfigError::InvalidField("target must be an array of tables")
  }
}

///|
/// Digits-only text to a non-negative Int; None on any other character.
fn digits_to_int(text : StringView) -> Int? {
  let mut value = 0
  for c in text {
    let v = c.to_int()
    if v < 48 || v > 57 {
      return None
    }
    value = value * 10 + (v - 48)
  }
  Some(value)
}

///|
/// Parse an interval: "Nm" (1~60 minutes), "Nh" (1~24 hours), "daily H"
/// (H 0~23), "weekly W H" (W 1~7, Monday first), "monthly D H" (D 1~28).
pub fn parse_interval(
  text : String,
  ctx : String,
) -> Interval raise ConfigError {
  let parts = text.split(" ").collect()
  match parts.length() {
    1 => {
      let spec = parts[0]
      guard spec.length() >= 2 else {
        raise ConfigError::InvalidField("\{ctx}.interval has invalid value")
      }
      let unit = spec[spec.length() - 1:].to_owned()
      let num_text = spec[:spec.length() - 1].to_owned()
      guard num_text.length() > 0 else {
        raise ConfigError::InvalidField("\{ctx}.interval has invalid value")
      }
      let mut digits = true
      for c in num_text {
        let v = c.to_int()
        if v < 48 || v > 57 {
          digits = false
          break
        }
      }
      guard digits else {
        raise ConfigError::InvalidField("\{ctx}.interval has invalid value")
      }
      let num = match digits_to_int(num_text) {
        Some(v) => v
        None =>
          raise ConfigError::InvalidField("\{ctx}.interval has invalid value")
      }
      match unit {
        "m" =>
          if num >= 1 && num <= 60 {
            Minutes(num)
          } else {
            raise ConfigError::InvalidField(
              "\{ctx}.interval minutes must be between 1 and 60",
            )
          }
        "h" =>
          if num >= 1 && num <= 24 {
            Hours(num)
          } else {
            raise ConfigError::InvalidField(
              "\{ctx}.interval hours must be between 1 and 24",
            )
          }
        _ =>
          raise ConfigError::InvalidField(
            "\{ctx}.interval must be like \"5m\", \"2h\", \"daily 8\", \"weekly 1 8\" or \"monthly 1 8\"",
          )
      }
    }
    2 => {
      let hour = parse_hour(parts[1], ctx)
      match parts[0].to_owned() {
        "daily" => Daily(hour)
        _ =>
          raise ConfigError::InvalidField(
            "\{ctx}.interval must be like \"daily 8\"",
          )
      }
    }
    3 => {
      let hour = parse_hour(parts[2], ctx)
      let day = match digits_to_int(parts[1]) {
        Some(v) => v
        None =>
          raise ConfigError::InvalidField("\{ctx}.interval has invalid value")
      }
      match parts[0].to_owned() {
        "weekly" =>
          if day >= 1 && day <= 7 {
            Weekly(day, hour)
          } else {
            raise ConfigError::InvalidField(
              "\{ctx}.interval weekday must be between 1 and 7",
            )
          }
        "monthly" =>
          if day >= 1 && day <= 28 {
            Monthly(day, hour)
          } else {
            raise ConfigError::InvalidField(
              "\{ctx}.interval day must be between 1 and 28",
            )
          }
        _ =>
          raise ConfigError::InvalidField(
            "\{ctx}.interval must be like \"weekly 1 8\" or \"monthly 1 8\"",
          )
      }
    }
    _ =>
      raise ConfigError::InvalidField(
        "\{ctx}.interval must be like \"5m\", \"2h\", \"daily 8\", \"weekly 1 8\" or \"monthly 1 8\"",
      )
  }
}

///|
/// The hour part of "daily H" / "weekly W H" / "monthly D H": digits 0~23.
fn parse_hour(text : StringView, ctx : String) -> Int raise ConfigError {
  guard text.length() > 0 else {
    raise ConfigError::InvalidField("\{ctx}.interval has invalid value")
  }
  let mut digits = true
  for c in text {
    let v = c.to_int()
    if v < 48 || v > 57 {
      digits = false
      break
    }
  }
  guard digits else {
    raise ConfigError::InvalidField("\{ctx}.interval has invalid value")
  }
  let hour = match digits_to_int(text) {
    Some(v) => v
    None => raise ConfigError::InvalidField("\{ctx}.interval has invalid value")
  }
  if hour >= 0 && hour <= 23 {
    hour
  } else {
    raise ConfigError::InvalidField(
      "\{ctx}.interval hour must be between 0 and 23",
    )
  }
}
