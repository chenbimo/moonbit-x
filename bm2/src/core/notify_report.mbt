///|
/// The bridge between supervision and notifications: it turns supervisor state
/// (instances, configs, sampled metrics) into messages, and decides when a
/// periodic health report or a threshold alert is due. Delivery policy itself
/// lives in the engine, and the policy for each message comes from the project
/// that produced it.

///|
/// How often thresholds and report schedules are evaluated. Cheap enough to run
/// on a timer rather than on every tick.
const NOTIFY_CHECK_INTERVAL_MS : UInt64 = 60000UL

///|
/// The `[notify]` policy of one project. A project that never configured
/// notifications gets the disabled policy, so callers stay unconditional.
fn Supervisor::project_policy(
  self : Supervisor,
  app_name : String,
) -> @config.NotifyConfig {
  match self.apps.get(app_name) {
    Some(app) => app.notify
    None => @config.NotifyConfig::disabled()
  }
}

///|
fn human_duration(ms : UInt64) -> String {
  let seconds = (ms / 1000UL).to_int()
  if seconds < 60 {
    return "\{seconds}s"
  }
  let minutes = seconds / 60
  if minutes < 60 {
    return "\{minutes}m \{seconds % 60}s"
  }
  let hours = minutes / 60
  if hours < 24 {
    return "\{hours}h \{minutes % 60}m"
  }
  "\{hours / 24}d \{hours % 24}h"
}

///|
fn instance_fields(inst : Instance, now : UInt64) -> Array[(String, String)] {
  let fields : Array[(String, String)] = [
    ("应用", inst.app_name),
    ("实例", inst.instance_id.to_string()),
    ("模式", inst.exec_mode),
    ("端口", inst.port.to_string()),
    ("PID", inst.pid.to_string()),
    ("状态", inst.status.as_string()),
    ("启动次数", inst.times.to_string()),
    ("连续异常", inst.restart_count.to_string()),
  ]
  if inst.started_at_ms > 0UL && now > inst.started_at_ms {
    fields.push(("运行时长", human_duration(now - inst.started_at_ms)))
  }
  fields
}

///|
fn instance_signature(event : String, inst : Instance) -> String {
  event +
  "|" +
  inst.app_name +
  "|" +
  inst.instance_id.to_string() +
  "|" +
  inst.last_reason.unwrap_or("")
}

///|
/// Report one instance-level event. The caller supplies the wording; policy
/// (subscription, dedupe, rate limit, delivery) is the engine's.
pub fn Supervisor::notify_instance(
  self : Supervisor,
  inst : Instance,
  event : String,
  level : String,
  title : String,
  body : String,
) -> Unit {
  let now = @dateku.now_ms()
  self.notify.emit(
    self.project_policy(inst.app_name),
    inst.app_name,
    @notify.Message::new(
      event,
      level,
      "\{inst.app_name} · \{title}",
      body,
      instance_signature(event, inst),
      now,
      fields=instance_fields(inst, now),
    ),
  )
}

///|
/// Report something about a whole project (a restart, a stop, a stopped project
/// after a reusePort violation) where no single instance is the subject.
pub fn Supervisor::notify_project(
  self : Supervisor,
  app_name : String,
  event : String,
  level : String,
  title : String,
  body : String,
  signature : String,
) -> Unit {
  let now = @dateku.now_ms()
  let instances = match self.instances.get(app_name) {
    Some(arr) => arr.length()
    None => 0
  }
  self.notify.emit(
    self.project_policy(app_name),
    app_name,
    @notify.Message::new(
      event,
      level,
      "\{app_name} · \{title}",
      body,
      signature,
      now,
      fields=[
        ("主机", self.notify.host),
        ("项目", app_name),
        ("实例数", instances.to_string()),
      ],
    ),
  )
}

///|
/// Online instance count of one project, for the daemon start notice.
pub fn Supervisor::online_count(self : Supervisor, app_name : String) -> Int {
  match self.instances.get(app_name) {
    Some(arr) => arr.filter(fn(inst) { inst.status is Online }).length()
    None => 0
  }
}

///|
/// One line per instance: status, memory, cpu, uptime, restarts, port. This is
/// what makes a periodic report worth reading — it shows load per process.
fn Supervisor::report_line(
  self : Supervisor,
  inst : Instance,
  now : UInt64,
) -> String {
  let mut line = inst.app_name +
    "/" +
    inst.instance_id.to_string() +
    " " +
    inst.status.as_string()
  line = line + " · 端口 " + inst.port.to_string()
  if inst.status is Online {
    match @subproc.read_rss_kb(inst.pid) {
      Some(kb) => line = line + " · RSS " + (kb / 1024).to_string() + "MB"
      None => ()
    }
    match
      self.notify.cpu_percent(
        inst.app_name + "/" + inst.instance_id.to_string(),
        inst.pid,
        now,
      ) {
      Some(percent) => line = line + " · CPU " + format_percent(percent) + "%"
      None => ()
    }
    if inst.started_at_ms > 0UL && now > inst.started_at_ms {
      line = line + " · 已运行 " + human_duration(now - inst.started_at_ms)
    }
  } else if inst.last_reason is Some(reason) {
    line = line + " · " + reason
  }
  if inst.restart_count > 0 {
    match self.apps.get(inst.app_name) {
      Some(app) =>
        line = line +
          " · 连续异常 " +
          inst.restart_count.to_string() +
          "/" +
          app.max_restarts.to_string()
      None => ()
    }
  }
  line
}

///|
fn format_percent(percent : Double) -> String {
  let scaled = (percent * 10.0 + 0.5).to_int()
  (scaled / 10).to_string() + "." + (scaled % 10).to_string()
}

///|
/// The periodic report for one project: every instance on one line, plus the
/// project's own shape. `report_fields` selects which of these appear.
fn Supervisor::build_report(
  self : Supervisor,
  app_name : String,
  policy : @config.NotifyConfig,
  now : UInt64,
) -> @notify.Message {
  let lines = []
  let mut online = 0
  let mut other = 0
  match self.instances.get(app_name) {
    Some(arr) =>
      for inst in arr {
        if inst.status is Online {
          online += 1
        } else if !(inst.status is Stopped) {
          other += 1
        }
        lines.push(self.report_line(inst, now))
      }
    None => ()
  }
  let fields : Array[(String, String)] = [("主机", self.notify.host)]
  if policy.report_fields.contains("status") {
    fields.push(("在线实例", online.to_string()))
    fields.push(("异常实例", other.to_string()))
  }
  if policy.report_fields.contains("ports") {
    match self.apps.get(app_name) {
      Some(config) => {
        fields.push(("执行模式", config.exec_mode))
        fields.push(("端口", config.port.to_string()))
      }
      None => ()
    }
  }
  @notify.Message::new(
    "report",
    if other > 0 {
      "warn"
    } else {
      "info"
    },
    "bm2 体检 · \{app_name}",
    if lines.length() == 0 {
      "当前没有实例。"
    } else {
      lines.join("\n")
    },
    "report|" + app_name,
    now,
    fields~,
  )
}

///|
/// Threshold alerts and the periodic report, evaluated once a minute per
/// project. Each condition is deduplicated by the engine, so something that
/// persists alerts once per dedupe window instead of on every pass.
pub fn Supervisor::check_notify(self : Supervisor, now : UInt64) -> Unit {
  if now >= self.last_notify_check_ms &&
    now - self.last_notify_check_ms < NOTIFY_CHECK_INTERVAL_MS {
    return
  }
  self.last_notify_check_ms = now
  for app_name in self.app_names() {
    let policy = self.project_policy(app_name)
    match self.instances.get(app_name) {
      Some(arr) =>
        for inst in arr {
          let key = app_name + "/" + inst.instance_id.to_string()
          if policy.threshold_restarts > 0 &&
            inst.restart_count >= policy.threshold_restarts {
            self.notify_instance(
              inst,
              "threshold",
              "warn",
              "重启过频",
              "连续异常重启 " +
              inst.restart_count.to_string() +
              " 次,已达到阈值 " +
              policy.threshold_restarts.to_string() +
              "。",
            )
          }
          if inst.status is Online || inst.status is Stopped {
            self.notify.forget_offline(key)
          } else if policy.threshold_offline_min > 0 {
            let since = self.notify.offline_since(key, now)
            let limit = (policy.threshold_offline_min * 60000).to_uint64()
            if now >= since && now - since >= limit {
              self.notify_instance(
                inst,
                "threshold",
                "warn",
                "实例长时间未恢复",
                "实例已处于 " +
                inst.status.as_string() +
                " 超过 " +
                policy.threshold_offline_min.to_string() +
                " 分钟。",
              )
            }
          }
        }
      None => ()
    }
    if policy.enabled && policy.report_interval_min > 0 {
      let interval = (policy.report_interval_min * 60000).to_uint64()
      let last = match self.last_report_ms.get(app_name) {
        Some(ms) => ms
        None => 0UL
      }
      if last == 0UL || (now >= last && now - last >= interval) {
        self.last_report_ms[app_name] = now
        self.notify.emit(
          policy,
          app_name,
          self.build_report(app_name, policy, now),
        )
      }
    }
  }
}

///|
/// Memory approaching the limit is worth knowing before the kill: the sampling
/// already happened in check_memory, so this costs nothing extra.
pub fn Supervisor::notify_memory_pressure(
  self : Supervisor,
  inst : Instance,
  rss_kb : Int,
) -> Unit {
  let policy = self.project_policy(inst.app_name)
  if policy.threshold_rss_percent <= 0 {
    return
  }
  let limit_kb = match self.apps.get(inst.app_name) {
    Some(app) => app.max_memory_mb * 1024
    None => 0
  }
  if limit_kb > 0 && rss_kb * 100 >= limit_kb * policy.threshold_rss_percent {
    self.notify_instance(
      inst,
      "threshold",
      "warn",
      "内存接近上限",
      "RSS " +
      (rss_kb / 1024).to_string() +
      "MB,已达上限 " +
      (limit_kb / 1024).to_string() +
      "MB 的 " +
      policy.threshold_rss_percent.to_string() +
      "% 。",
    )
  }
}
