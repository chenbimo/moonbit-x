///|
/// bm2 的通知适配层:订阅过滤(events/levels)、事件日志与监督采样留在这里,
/// 投递、去重、限流与重试委托给 chensuiyi/notify 库。库返回结构化结果,
/// 是否落日志由 bm2 决定。

///|
pub struct Notifier {
  engine : @notify.Engine
  ctx : @notify.Context
  host : String
  state_dir : String
  /// Instance key → when it was first seen away from online, and the previous
  /// cpu sample, both kept here so `Instance` stays about supervision only.
  offline_since : Map[String, UInt64]
  cpu_samples : Map[String, (UInt64, UInt64)]
}

///|
/// An engine with no policy of its own: each project brings its own when it
/// emits an event. `host` brands outgoing messages and the SMTP greeting.
pub fn Notifier::new(state_dir : String, host : String) -> Notifier {
  let ctx : @notify.Context = { host, product: "bm2", }
  {
    engine: @notify.Engine::new(ctx),
    ctx,
    host,
    state_dir,
    offline_since: Map([]),
    cpu_samples: Map([]),
  }
}

///|
/// When this instance was first seen away from `online`. Recording the first
/// sighting — not the latest — is what makes "stuck for N minutes" meaningful.
pub fn Notifier::offline_since(
  self : Notifier,
  key : String,
  now : UInt64,
) -> UInt64 {
  match self.offline_since.get(key) {
    Some(since) => since
    None => {
      self.offline_since[key] = now
      now
    }
  }
}

///|
pub fn Notifier::forget_offline(self : Notifier, key : String) -> Unit {
  self.offline_since.remove(key)
}

///|
/// CPU percent since the previous sample of the same instance. The first call
/// only records a baseline, so a fresh daemon reports no CPU rather than a
/// number invented from a missing previous sample.
pub fn Notifier::cpu_percent(
  self : Notifier,
  key : String,
  pid : Int,
  now : UInt64,
) -> Double? {
  match @subproc.read_cpu_ticks(pid) {
    None => None
    Some(ticks) =>
      match self.cpu_samples.get(key) {
        Some(sample) => {
          let (last_ticks, last_ms) = sample
          self.cpu_samples[key] = (ticks, now)
          if now <= last_ms || ticks < last_ticks {
            None
          } else {
            let elapsed_s = (now - last_ms).to_double() / 1000.0
            if elapsed_s <= 0.0 {
              None
            } else {
              let busy_s = (ticks - last_ticks).to_double() /
                @subproc.clk_tck().to_double()
              Some(busy_s / elapsed_s * 100.0)
            }
          }
        }
        None => {
          self.cpu_samples[key] = (ticks, now)
          None
        }
      }
  }
}

///|
/// Messages dropped since the daemon started: queue overflow plus rate
/// limiting.
pub fn Notifier::dropped(self : Notifier) -> Int {
  self.engine.dropped()
}

///|
/// Messages currently queued.
pub fn Notifier::queued(self : Notifier) -> Int {
  self.engine.queued()
}

///|
/// A message for `bm2 notify`: proves a project's endpoints and credentials work
/// without waiting for a real incident.
pub fn test_message(now : UInt64) -> @notify.Message {
  @notify.Message::new(
    "lifecycle", "info", "bm2 notification test", "If you see this message, the notification target is configured correctly.",
    "notify-test", now,
  )
}

///|
fn level_rank(level : String) -> Int {
  match level {
    "error" => 2
    "warn" => 1
    _ => 0
  }
}

///|
/// Which targets receive one event: the global subscription, the target's own
/// override, and the level floor.
fn wants(
  target : @config.NotifyTarget,
  policy : @config.NotifyConfig,
  msg : @notify.Message,
) -> Bool {
  let events = match target.events {
    Some(events) => events
    None => policy.events
  }
  if !events.contains(msg.event) {
    return false
  }
  if msg.event == "report" {
    match target.report {
      Some(false) => return false
      _ => ()
    }
  }
  match target.min_level {
    Some(minimum) => level_rank(msg.level) >= level_rank(minimum)
    None => true
  }
}

///|
/// bm2.toml 的 target 携带订阅字段(events/min_level/report/label),投递用不到;
/// 转换为库的中立 Target。
fn lib_target(target : @config.NotifyTarget) -> @notify.Target {
  {
    name: target.name,
    preset: target.preset,
    url: target.url,
    secret: target.secret,
    format: target.format,
    from: target.from,
    to: target.to,
    username: target.username,
    password: target.password,
  }
}

///|
fn lib_targets(targets : Array[@config.NotifyTarget]) -> Array[@notify.Target] {
  targets.map(lib_target)
}

///|
/// The single entry point for events: subscription, deduplication, rate limit,
/// then the queue. Callers describe what happened; policy lives here.
pub fn Notifier::emit(
  self : Notifier,
  policy : @config.NotifyConfig,
  app : String,
  msg : @notify.Message,
) -> Unit {
  if !policy.enabled {
    return
  }
  if !policy.events.contains(msg.event) {
    return
  }
  let targets = policy.targets.filter(fn(target) { wants(target, policy, msg) })
  if targets.length() == 0 {
    return
  }
  let outcome = self.engine.emit(
    msg.ts_ms,
    msg.key,
    app,
    msg,
    lib_targets(targets),
    policy.timeout_ms,
    dedupe_window_s=policy.dedupe_window_s,
    rate_per_minute=policy.max_per_minute,
    queue_limit=policy.queue_size,
  )
  match outcome {
    RateLimited =>
      log_event(
        self.state_dir,
        "bm2d.events.jsonl",
        "notify_rate_limited",
        app=Some(app),
        detail=msg.event,
      )
    _ => ()
  }
}

///|
/// One pass of the engine: deliver at most one queued message. Returns the
/// number of messages still queued; the outcome lands in the event log.
pub async fn Notifier::pump(self : Notifier, now : UInt64) -> Int {
  let report = self.engine.pump(now)
  match report.outcome {
    Partial =>
      log_event(
        self.state_dir,
        "bm2d.events.jsonl",
        "notify_partial",
        app=report.owner,
        detail="partial delivery",
      )
    Failed(attempt~) =>
      log_event(
        self.state_dir,
        "bm2d.events.jsonl",
        "notify_failed",
        app=report.owner,
        detail="attempt \{attempt}/3",
      )
    Exhausted =>
      log_event(
        self.state_dir,
        "bm2d.events.jsonl",
        "notify_failed",
        app=report.owner,
        detail="attempt 3/3, dropped",
      )
    _ => ()
  }
  report.remaining
}

///|
/// Deliver immediately, ignoring subscriptions — this is `bm2 notify`, where the
/// operator explicitly asks for a message on a project's targets.
pub async fn Notifier::deliver_now(
  self : Notifier,
  targets : Array[@config.NotifyTarget],
  timeout_ms : Int,
  target_name : String?,
  msg : @notify.Message,
) -> Array[(String, String?)] {
  let chosen = match target_name {
    Some(name) => targets.filter(fn(target) { target.name == name })
    None => targets
  }
  let results = @notify.deliver_all(
    lib_targets(chosen),
    msg,
    timeout_ms,
    self.ctx,
  )
  for pair in results {
    let (name, failure) = pair
    log_event(
      self.state_dir,
      "bm2d.events.jsonl",
      match failure {
        None => "notify_sent"
        Some(_) => "notify_target_failed"
      },
      app=Some(name),
      detail=match failure {
        None => msg.event
        Some(reason) => msg.event + ": " + reason
      },
    )
  }
  results
}
