///|
/// Validation for the `[notify]` section. Every rule states a bound or a closed
/// set, and no error message ever echoes `url`, `secret`, `username` or
/// `password`: those fields are credentials, and the CLI and event log print
/// these messages verbatim.

///|
fn check_int_range(
  value : Int,
  low : Int,
  high : Int,
  ctx : String,
) -> Unit raise ConfigError {
  if value < low || value > high {
    raise ConfigError::InvalidField("\{ctx} must be between \{low} and \{high}")
  }
}

///|
fn check_members(
  values : Array[String],
  allowed : Array[String],
  ctx : String,
) -> Unit raise ConfigError {
  for value in values {
    if !allowed.contains(value) {
      raise ConfigError::InvalidField("\{ctx} has unknown value \{value}")
    }
  }
}

///|
fn check_scheme(
  url : String,
  prefixes : Array[String],
  ctx : String,
) -> Unit raise ConfigError {
  let lowered = url.to_lower()
  let mut ok = false
  for prefix in prefixes {
    if lowered.has_prefix(prefix) {
      ok = true
    }
  }
  if !ok {
    let mut allowed = ""
    for prefix in prefixes {
      allowed = allowed + " " + prefix
    }
    raise ConfigError::InvalidField("\{ctx} must start with one of:\{allowed}")
  }
}

///|
fn require_field(
  value : String?,
  ctx : String,
  field : String,
) -> Unit raise ConfigError {
  match value {
    Some(v) if !v.is_empty() => ()
    _ => raise ConfigError::InvalidField("\{ctx}.\{field} is required")
  }
}

///|
fn forbid_field(
  value : String?,
  ctx : String,
  field : String,
) -> Unit raise ConfigError {
  match value {
    Some(_) =>
      raise ConfigError::InvalidField(
        "\{ctx}.\{field} is not used by this preset",
      )
    None => ()
  }
}

///|
pub fn validate_notify(config : NotifyConfig) -> Unit raise ConfigError {
  check_int_range(config.timeout_ms, 100, 60000, "notify.timeout_ms")
  check_int_range(config.dedupe_window_s, 0, 604800, "notify.dedupe_window_s")
  check_int_range(config.max_per_minute, 0, 6000, "notify.max_per_minute")
  check_int_range(config.queue_size, 1, 4096, "notify.queue_size")
  check_int_range(
    config.report_interval_min,
    0,
    10080,
    "notify.report_interval_min",
  )
  check_int_range(config.include_log_lines, 0, 50, "notify.include_log_lines")
  // The internal default -1 means "off" and skips the range check; explicit
  // negative values never reach here (req_int rejects them earlier).
  if config.daily_report_hour >= 0 {
    check_int_range(config.daily_report_hour, 0, 23, "notify.daily_report_hour")
  }
  check_int_range(
    config.threshold_rss_percent,
    0,
    100,
    "notify.threshold_rss_percent",
  )
  check_int_range(
    config.threshold_offline_min,
    0,
    1440,
    "threshold_offline_min",
  )
  check_int_range(
    config.threshold_restarts,
    0,
    1000,
    "notify.threshold_restarts",
  )
  check_int_range(config.start_timeout_ms, 0, 600000, "notify.start_timeout_ms")
  check_int_range(
    config.threshold_disk_mb,
    0,
    1048576,
    "notify.threshold_disk_mb",
  )
  check_int_range(config.threshold_storm, 0, 1000, "notify.threshold_storm")
  check_members(config.events, notifyEvents, "notify.events")
  check_members(
    config.report_fields,
    notifyReportFields,
    "notify.report_fields",
  )
  let seen : Map[String, Unit] = Map([])
  for index, target in config.targets {
    // The index, never the URL, is what a message may mention.
    let ctx = "notify.target[\{index}]"
    if target.name.is_empty() {
      raise ConfigError::InvalidField("\{ctx}.name must not be empty")
    }
    if seen.contains(target.name) {
      raise ConfigError::InvalidField("duplicate target name: \{target.name}")
    }
    seen[target.name] = ()
    check_members([target.preset], presets, "\{ctx}.preset")
    match target.format {
      Some(format) => check_members([format], notifyFormats, "\{ctx}.format")
      None => ()
    }
    match target.min_level {
      Some(level) => check_members([level], notifyLevels, "\{ctx}.min_level")
      None => ()
    }
    match target.events {
      Some(events) => check_members(events, notifyEvents, "\{ctx}.events")
      None => ()
    }
    if target.preset == "email" {
      check_scheme(target.url, ["smtp://", "smtps://"], "\{ctx}.url")
      require_field(target.from, ctx, "from")
      match target.to {
        Some(recipients) =>
          if recipients.is_empty() {
            raise ConfigError::InvalidField("\{ctx}.to must not be empty")
          }
        None => raise ConfigError::InvalidField("\{ctx}.to is required")
      }
    } else {
      check_scheme(target.url, ["http://", "https://"], "\{ctx}.url")
      forbid_field(target.from, ctx, "from")
      forbid_field(target.password, ctx, "password")
      if target.to is Some(_) {
        raise ConfigError::InvalidField("\{ctx}.to is not used by this preset")
      }
      match target.preset {
        "pushover" => {
          // Pushover needs the application token and the user key.
          require_field(target.secret, ctx, "secret")
          require_field(target.username, ctx, "username")
        }
        "pushplus" | "pagerduty" | "opsgenie" =>
          require_field(target.secret, ctx, "secret")
        "telegram" => require_field(target.username, ctx, "username")
        _ => ()
      }
    }
  }
}
