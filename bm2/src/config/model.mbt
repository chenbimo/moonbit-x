///|
/// One bm2.toml configures exactly one project (single app, one or more
/// instances). The project name is also the app name and must be unique
/// among all registered projects.
pub(all) struct Config {
  name : String
  cwd : String
  script : String
  runtime : String
  exec_mode : String
  instances : Int
  port : Int
  max_memory_mb : Int
  max_restarts : Int
  restart_delay_ms : Int
  min_uptime_ms : Int
  stop_timeout_ms : Int
  /// Notification policy for this project: which events leave the machine and
  /// where they go. Written as `[notify]` plus `[[notify.target]]` in bm2.toml,
  /// so a project's supervision and its reporting stay in one file.
  notify : NotifyConfig
  /// Application environment from the `[env]` table, injected into every
  /// instance after the whitelist and before the reserved vars, so it beats
  /// .env files (bun never overrides an existing variable) but never the
  /// reserved BM2_*/NODE_ENV set.
  env : Array[(String, String)]
} derive(Debug)

///|
pub extend Config with Debug::{to_repr}

///|
/// One notification destination. `preset` picks the platform's payload shape
/// and authentication; the remaining fields are the endpoint and its
/// credentials. url/secret/password/username are sensitive: they are never
/// echoed in errors, events or CLI output.
pub(all) struct NotifyTarget {
  name : String
  preset : String
  url : String
  secret : String?
  format : String?
  events : Array[String]?
  min_level : String?
  report : Bool?
  label : String?
  /// email preset only.
  from : String?
  to : Array[String]?
  /// email preset only; both are optional for servers that accept mail
  /// without authentication (relay on localhost).
  username : String?
  password : String?
} derive(Debug)

///|
pub extend NotifyTarget with Debug::{to_repr}

///|
/// Which events leave this project, and where they go. Lives inside the project
/// config: a project's supervision and its reporting are one unit.
pub(all) struct NotifyConfig {
  enabled : Bool
  /// Notification copy language: "en" (default) or "zh". Only what a human
  /// reads in a chat group is translated; CLI/log/JSON stay language-neutral.
  lang : String
  timeout_ms : Int
  dedupe_window_s : Int
  max_per_minute : Int
  queue_size : Int
  events : Array[String]
  report_interval_min : Int
  report_fields : Array[String]
  daily_report_hour : Int
  include_log_lines : Int
  threshold_rss_percent : Int
  threshold_offline_min : Int
  threshold_restarts : Int
  start_timeout_ms : Int
  threshold_disk_mb : Int
  threshold_storm : Int
  targets : Array[NotifyTarget]
} derive(Debug)

///|
pub extend NotifyConfig with Debug::{to_repr}

///|
/// Notifications are off until a project says otherwise, so a bm2.toml without
/// a notify section is a valid, silent project.
pub fn NotifyConfig::disabled() -> NotifyConfig {
  {
    enabled: false,
    lang: "en",
    timeout_ms: 5000,
    dedupe_window_s: 3600,
    max_per_minute: 30,
    queue_size: 128,
    events: [],
    report_interval_min: 0,
    report_fields: ["status", "rss", "restarts", "uptime", "ports"],
    daily_report_hour: -1,
    include_log_lines: 0,
    threshold_rss_percent: 0,
    threshold_offline_min: 0,
    threshold_restarts: 0,
    start_timeout_ms: 0,
    threshold_disk_mb: 0,
    threshold_storm: 0,
    targets: [],
  }
}

///|
pub(all) suberror ConfigError {
  InvalidDocument(String)
  InvalidField(String)
}

///|
pub impl Show for ConfigError with fn output(self, logger) {
  match self {
    InvalidDocument(message) => {
      logger.write_string("InvalidDocument: ")
      logger.write_string(message)
    }
    InvalidField(message) => {
      logger.write_string("InvalidField: ")
      logger.write_string(message)
    }
  }
}

///|
pub extend ConfigError with Show::{to_string, output}
