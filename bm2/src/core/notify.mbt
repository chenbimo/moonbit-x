///|
/// The notification engine. It sits on the daemon's single thread: events are
/// queued, and `pump` (called from every tick) delivers at most one message per
/// pass. Nothing here may ever make supervision depend on a remote endpoint —
/// every failure path degrades to an entry in the daemon event log.
///
/// Policy is per project: the caller passes the `notify` section of the project
/// that owns the event, and the engine resolves which of that project's targets
/// want it before the message is queued.

///|
pub(all) suberror NotifyError {
  InvalidPreset(String)
  /// Rendering or delivery failed; the text never contains a credential.
  DeliveryFailed(String)
}

///|
pub impl Show for NotifyError with fn output(self, logger) {
  match self {
    InvalidPreset(preset) => {
      logger.write_string("unknown preset: ")
      logger.write_string(preset)
    }
    DeliveryFailed(detail) => {
      logger.write_string("delivery failed: ")
      logger.write_string(detail)
    }
  }
}

///|
pub extend NotifyError with Show::{to_string, output}

///|
/// One notification, assembled by the code that knows the context (the
/// supervisor for instance events, the report builder for health summaries).
/// `signature` is what deduplication keys on.
pub(all) struct NotifyMessage {
  event : String
  level : String
  title : String
  body : String
  fields : Array[(String, String)]
  ts_ms : UInt64
  signature : String
} derive(Debug)

///|
pub extend NotifyMessage with Debug::{to_repr}

///|
pub fn NotifyMessage::new(
  event : String,
  level : String,
  title : String,
  body : String,
  signature : String,
  ts_ms : UInt64,
  fields? : Array[(String, String)] = [],
) -> NotifyMessage {
  { event, level, title, body, fields, ts_ms, signature, }
}

///|
/// A rendered request: what the transport hands to curl. Kept separate from the
/// message so one message can be rendered per target.
pub(all) struct Delivery {
  url : String
  http_method : String
  content_type : String?
  headers : Array[(String, String)]
  body : String
  /// email: the complete RFC5322 message, uploaded as a file.
  mail : String?
} derive(Debug)

///|
pub extend Delivery with Debug::{to_repr}

///|
struct DedupeEntry {
  first_ms : UInt64
  count : Int
}

///|
/// A message plus the delivery facts resolved when it was queued: one project's
/// targets and that project's timeout.
struct QueuedNotice {
  message : NotifyMessage
  /// Owning project, for per-project queue accounting.
  app : String
  targets : Array[@config.NotifyTarget]
  timeout_ms : Int
}

///|
const NOTIFY_MAX_ATTEMPTS : Int = 3

///|
pub struct Notifier {
  state_dir : String
  mut queue : Array[QueuedNotice]
  mut dropped : Int
  mut window_sent : Int
  mut window_started_ms : UInt64
  dedupe : Map[String, DedupeEntry]
  mut next_attempt_ms : UInt64
  mut attempts : Int
  /// Instance key → when it was first seen away from online, and the previous
  /// cpu sample, both kept here so `Instance` stays about supervision only.
  offline_since : Map[String, UInt64]
  cpu_samples : Map[String, (UInt64, UInt64)]
  host : String
}

///|
/// An engine with no policy of its own: each project brings its own when it
/// emits an event.
pub fn Notifier::new(state_dir : String) -> Notifier {
  @process.discard(() => @process.mkdir_p(state_dir + "/notify", mode=0o700))
  {
    state_dir,
    queue: [],
    dropped: 0,
    window_sent: 0,
    window_started_ms: 0UL,
    dedupe: Map([]),
    next_attempt_ms: 0UL,
    attempts: 0,
    offline_since: Map([]),
    cpu_samples: Map([]),
    host: @process.hostname(),
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
  match @process.read_cpu_ticks(pid) {
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
                @process.clk_tck().to_double()
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
  self.dropped
}

///|
/// A message for `bm2 notify`: proves a project's endpoints and credentials work
/// without waiting for a real incident.
pub fn test_message(now : UInt64) -> NotifyMessage {
  NotifyMessage::new(
    "lifecycle", "info", "bm2 通知测试", "如果你看到这条消息,说明该通知目标配置可用。",
    "notify-test", now,
  )
}

///|
/// Which targets receive one event: the global subscription, the target's own
/// override, and the level floor.
fn wants(
  target : @config.NotifyTarget,
  policy : @config.NotifyConfig,
  msg : NotifyMessage,
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
/// The single entry point for events: subscription, deduplication, rate limit,
/// then the queue. Callers describe what happened; policy lives here.
pub fn Notifier::emit(
  self : Notifier,
  policy : @config.NotifyConfig,
  app : String,
  msg : NotifyMessage,
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
  let now = msg.ts_ms
  let mut message = msg
  if policy.dedupe_window_s > 0 {
    let window = (policy.dedupe_window_s * 1000).to_uint64()
    match self.dedupe.get(msg.signature) {
      Some(entry) =>
        if now >= entry.first_ms && now - entry.first_ms < window {
          // Same condition inside the window: count it, stay silent.
          self.dedupe[msg.signature] = {
            first_ms: entry.first_ms,
            count: entry.count + 1,
          }
          return
        } else {
          // The window expired: send again and say how quiet it has been.
          if entry.count > 1 {
            message = {
              ..message,
              body: message.body +
              "\n(上一个窗口内同样的事件共 \{entry.count} 次)",
            }
          }
          self.dedupe[msg.signature] = { first_ms: now, count: 1, }
        }
      None => self.dedupe[msg.signature] = { first_ms: now, count: 1, }
    }
  }
  if now >= self.window_started_ms && now - self.window_started_ms >= 60000UL {
    self.window_started_ms = now
    self.window_sent = 0
  }
  if policy.max_per_minute > 0 && self.window_sent >= policy.max_per_minute {
    self.dropped += 1
    log_event(
      self.state_dir,
      "bm2d.events.jsonl",
      "notify_rate_limited",
      app=Some(app),
      detail=message.event,
    )
    return
  }
  let queued = self.queue.filter(fn(notice) { notice.app == app }).length()
  if queued >= policy.queue_size {
    // Keep the first events of a burst: they carry the root cause.
    self.dropped += 1
    return
  }
  self.queue.push({ message, app, targets, timeout_ms: policy.timeout_ms, })
}

///|
/// One pass of the engine: deliver at most one queued message. Returns the
/// number of messages still queued.
pub async fn Notifier::pump(self : Notifier, now : UInt64) -> Int {
  if self.queue.length() == 0 || now < self.next_attempt_ms {
    return self.queue.length()
  }
  let notice = self.queue[0]
  let results = self.deliver_all(
    notice.targets,
    notice.timeout_ms,
    notice.message,
  )
  let delivered = results.filter(fn(pair) {
    let (_, failure) = pair
    failure is None
  })
  let failures = results.filter(fn(pair) {
    let (_, failure) = pair
    failure is Some(_)
  })
  if failures.length() == 0 {
    self.drop_head()
    self.attempts = 0
    self.next_attempt_ms = 0UL
    self.window_sent += 1
  } else if delivered.length() > 0 {
    // Somebody got it; retrying now would only duplicate it for them.
    self.drop_head()
    self.attempts = 0
    self.next_attempt_ms = 0UL
    log_event(
      self.state_dir,
      "bm2d.events.jsonl",
      "notify_partial",
      app=Some(notice.app),
      detail=notice.message.event,
    )
  } else {
    self.attempts += 1
    log_event(
      self.state_dir,
      "bm2d.events.jsonl",
      "notify_failed",
      app=Some(notice.app),
      detail=notice.message.event +
        " (" +
        self.attempts.to_string() +
        "/" +
        NOTIFY_MAX_ATTEMPTS.to_string() +
        ")",
    )
    if self.attempts >= NOTIFY_MAX_ATTEMPTS {
      self.drop_head()
      self.attempts = 0
      self.next_attempt_ms = 0UL
    } else {
      // 5s then 15s: long enough to clear a blip, short enough for a crash alert.
      self.next_attempt_ms = now +
        (5000 * (1 + 2 * (self.attempts - 1))).to_uint64()
    }
  }
  self.queue.length()
}

///|
fn Notifier::drop_head(self : Notifier) -> Unit {
  self.queue = self.queue[1:].to_owned()
}

///|
async fn Notifier::deliver_all(
  self : Notifier,
  targets : Array[@config.NotifyTarget],
  timeout_ms : Int,
  msg : NotifyMessage,
) -> Array[(String, String?)] {
  let results = []
  for target in targets {
    results.push((target.name, self.deliver(target, timeout_ms, msg)))
  }
  results
}

///|
/// Deliver immediately, ignoring subscriptions — this is `bm2 notify`, where the
/// operator explicitly asks for a message on a project's targets.
pub async fn Notifier::deliver_now(
  self : Notifier,
  targets : Array[@config.NotifyTarget],
  timeout_ms : Int,
  target_name : String?,
  msg : NotifyMessage,
) -> Array[(String, String?)] {
  let chosen = match target_name {
    Some(name) => targets.filter(fn(target) { target.name == name })
    None => targets
  }
  self.deliver_all(chosen, timeout_ms, msg)
}

///|
/// Send one message to one target. None means the endpoint accepted it; Some
/// carries a credential-free reason.
async fn Notifier::deliver(
  self : Notifier,
  target : @config.NotifyTarget,
  timeout_ms : Int,
  msg : NotifyMessage,
) -> String? {
  let delivery = try render_delivery(target, msg, self.host) catch {
    e => return Some(e.to_string())
  } noraise {
    rendered => rendered
  }
  let failure = self.transport(target, delivery, timeout_ms)
  log_event(
    self.state_dir,
    "bm2d.events.jsonl",
    match failure {
      None => "notify_sent"
      Some(_) => "notify_target_failed"
    },
    app=Some(target.name),
    detail=match failure {
      None => msg.event
      Some(reason) => msg.event + ": " + reason
    },
  )
  failure
}

///|
/// 飞书、钉钉、企业微信都是"HTTP 200 + 响应体错误码":只看状态码会把 token
/// 错误当成投递成功。应答形状对不上(空 body、纯文本)一律视为成功,避免把
/// 不认识的结构误报为失败。
fn body_failure(preset : String, body : String) -> String? {
  let code_key = match preset {
    "feishu" => "code"
    "dingtalk" | "wecom" => "errcode"
    _ => return None
  }
  let parsed = try @json.parse(body) catch {
    _ => return None
  } noraise {
    value => value
  }
  guard parsed is Object(fields) else { return None }
  let code = match fields.get(code_key) {
    Some(Number(value, ..)) => value.to_int()
    _ => return None
  }
  if code == 0 {
    return None
  }
  let mut reason = preset + " code " + code.to_string()
  match fields.get("msg") {
    Some(String(text)) if text != "" => reason = reason + ": " + text
    _ => ()
  }
  match fields.get("errmsg") {
    Some(String(text)) if text != "" => reason = reason + ": " + text
    _ => ()
  }
  Some(reason)
}

///|
/// Deliver one rendered request over the network. None means the endpoint
/// accepted it; Some carries a credential-free reason. HTTP presets go
/// through the async HTTP client; email speaks SMTP directly.
async fn Notifier::transport(
  self : Notifier,
  target : @config.NotifyTarget,
  delivery : Delivery,
  timeout_ms : Int,
) -> String? {
  match delivery.mail {
    Some(mail) => smtp_deliver(target, delivery, mail, self.host, timeout_ms)
    None => http_deliver(target, delivery, timeout_ms)
  }
}

///|
/// HTTP presets: one request, whole-call timeout. Non-2xx is a failure; for
/// feishu/dingtalk/wecom the response body is inspected too, because they
/// report credential errors as "200 + errcode".
async fn http_deliver(
  target : @config.NotifyTarget,
  delivery : Delivery,
  timeout_ms : Int,
) -> String? {
  let headers : Map[@http.CaseInsensitiveString, String] = Map([])
  match delivery.content_type {
    Some(content_type) =>
      headers[@http.CaseInsensitiveString("Content-Type")] = content_type
    None => ()
  }
  for pair in delivery.headers {
    let (key, value) = pair
    headers[@http.CaseInsensitiveString(key)] = value
  }
  let exchange = async fn() {
    match delivery.http_method {
      "GET" => @http.get(delivery.url, headers~)
      "PUT" => @http.put(delivery.url, delivery.body, headers~)
      _ => @http.post(delivery.url, delivery.body, headers~)
    }
  }
  let answer = try @async.with_timeout_opt(timeout_ms, exchange) catch {
    e => return Some(e.to_string())
  } noraise {
    answer => answer
  }
  match answer {
    None => Some("did not finish within " + timeout_ms.to_string() + "ms")
    Some((resp, body)) => {
      if resp.code < 200 || resp.code >= 300 {
        return Some("HTTP " + resp.code.to_string() + " " + resp.reason)
      }
      body_failure(target.preset, @utf8.decode_lossy(body.binary()))
    }
  }
}
