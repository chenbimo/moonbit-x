///|
/// Validation helpers for the `[notify]` section. Every failure names the
/// field and the target index; no error ever echoes a URL or a credential.

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
  schemes : Array[String],
  ctx : String,
) -> Unit raise ConfigError {
  for scheme in schemes {
    if url.has_prefix(scheme) {
      return
    }
  }
  raise ConfigError::InvalidField(
    "\{ctx}.url must start with one of:\{schemes.join(", ")}",
  )
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
  check_int_range(config.threshold_rss_percent, 0, 100, "notify.threshold_rss_percent")
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
  // The mail channel must exist before any email target can use it.
  match config.mail_url {
    Some(url) => check_scheme(url, ["smtp://", "smtps://"], "notify.mail_url")
    None => ()
  }
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
    match target.format {
      Some(format) => check_members([format], notifyFormats, "\{ctx}.format")
      None => ()
    }
    // Periodic targets: content already validated at parse time, schedule
    // already parsed; they take no event routing.
    if target.interval is Some(_) {
      ()
    } else {
      match target.events {
        Some(events) => check_members(events, notifyEvents, "\{ctx}.events")
        None => ()
      }
      match target.min_level {
        Some(level) => check_members([level], notifyLevels, "\{ctx}.min_level")
        None => ()
      }
    }
    // Platform-specific connection rules.
    match target.platform {
      "email" => {
        // Recipients here; server, sender and auth come from the channel.
        match target.mail_to {
          Some(recipients) =>
            if recipients.is_empty() {
              raise ConfigError::InvalidField(
                "\{ctx}.email.to must not be empty",
              )
            }
          None =>
            raise ConfigError::InvalidField("\{ctx}.email.to is required")
        }
        match config.mail_url {
          Some(_) => ()
          None =>
            raise ConfigError::InvalidField(
              "\{ctx} uses the email platform but notify has no mail_url",
            )
        }
      }
      "feishu" | "dingtalk" | "webhook" => {
        check_scheme(target.url, ["http://", "https://"], "\{ctx}.url")
      }
      "wecom" | "slack" | "discord" => {
        check_scheme(target.url, ["http://", "https://"], "\{ctx}.url")
      }
      _ =>
        raise ConfigError::InvalidField(
          "\{ctx}.platform has unknown value \{target.platform}",
        )
    }
  }
}
