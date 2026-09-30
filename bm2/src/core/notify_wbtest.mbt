///|
/// Tests for the notification engine and its platform presets. Everything runs
/// against real rendering, real signing and a real curl invocation, because the
/// parts that break in practice are the escaping and the credential handling.

///|
fn wb_target(
  preset : String,
  url : String,
  secret? : String,
  format? : String,
  events? : Array[String],
  min_level? : String,
  report? : Bool,
  from? : String,
  to? : Array[String],
  username? : String,
  password? : String,
) -> @config.NotifyTarget {
  {
    name: "t",
    preset,
    url,
    secret,
    format,
    events,
    min_level,
    report,
    label: None,
    from,
    to,
    username,
    password,
  }
}

///|
fn wb_message(level : String, ts_ms : UInt64) -> NotifyMessage {
  NotifyMessage::new(
    "crash",
    level,
    "api · 实例异常退出",
    "退出码 1",
    "crash|api|0|exit_code",
    ts_ms,
    fields=[("应用", "api"), ("端口", "3000")],
  )
}

///|
/// Parse a bm2.toml carrying the given `[notify]` section and hand back its
/// policy — the same path the daemon takes when it loads a project.
fn wb_policy(notify_section : String) -> @config.NotifyConfig raise {
  let doc = "name = \"api\"\nscript = \"index.ts\"\ninstances = 1\nport = 3000\n" +
    notify_section
  @config.parse(doc, "/srv/api").notify
}

///|
/// An engine with its own scratch state directory (it writes request files
/// there). Policy comes from the project, not from the engine.
fn wb_notifier(tag : String) -> Notifier raise {
  let root = "/tmp/bm2-notify-\{tag}-\{@process.get_pid()}"
  @process.mkdir_p(root)
  Notifier::new(root)
}

///|
test "request signing matches the platforms' published vectors" {
  // DingTalk: base64(HMAC-SHA256(key = secret, msg = "timestamp\n" + secret)),
  // percent-encoded, timestamp in milliseconds.
  assert_eq(
    dingtalk_signature("SECtest", 1700000000000UL),
    "aZLLrriXgn05YbwaGR7knYsLeJADjr9NwLaNNKpxh4g%3D",
  )
  // Feishu: base64(HMAC-SHA256(key = "timestamp\n" + secret, msg = "")),
  // timestamp in seconds — the inverse key/message arrangement.
  assert_eq(
    feishu_signature("SECtest", 1700000000UL),
    "G7XpBpG8NgG02fJOAhX6FRAObIljmFoxVReo8I62pEk=",
  )
}

///|
test "escaping survives the json layer" {
  assert_eq(json_escape("a\"b\\c\nd"), "a\\\"b\\\\c\\nd")
  assert_eq(json_escape("\u{1}"), "\\u0001")
  assert_eq(jstr("x"), "\"x\"")
  assert_eq(url_encode("a b/c?d=e&f"), "a%20b%2Fc%3Fd%3De%26f")
  assert_eq(url_encode("中文"), "%E4%B8%AD%E6%96%87")
  assert_eq(url_encode("AZaz09-_.~"), "AZaz09-_.~")
}

///|
test "the chinese chat presets carry their signature and shape" {
  let msg = wb_message("warn", 1700000000000UL)
  let feishu = render_delivery(
    wb_target(
      "feishu",
      "https://open.feishu.cn/open-apis/bot/v2/hook/x",
      secret="SECtest",
    ),
    msg,
    "host1",
  )
  assert_true(feishu.body.contains("\"msg_type\":\"interactive\""))
  assert_true(feishu.body.contains("\"timestamp\":\"1700000000\""))
  assert_true(
    feishu.body.contains("G7XpBpG8NgG02fJOAhX6FRAObIljmFoxVReo8I62pEk="),
  )
  assert_true(feishu.body.contains("lark_md"))

  let dingtalk = render_delivery(
    wb_target(
      "dingtalk",
      "https://oapi.dingtalk.com/robot/send?access_token=t",
      secret="SECtest",
    ),
    msg,
    "host1",
  )
  assert_true(dingtalk.url.contains("timestamp=1700000000000"))
  assert_true(
    dingtalk.url.contains("sign=aZLLrriXgn05YbwaGR7knYsLeJADjr9NwLaNNKpxh4g%3D"),
  )
  assert_true(dingtalk.body.contains("\"msgtype\":\"markdown\""))
  // A token already in the query string must be joined with &, not ?.
  assert_true(dingtalk.url.contains("?access_token=t&timestamp="))

  let wecom = render_delivery(
    wb_target("wecom", "https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=k"),
    msg,
    "host1",
  )
  assert_true(wecom.body.contains("\"msgtype\":\"markdown\""))
}

///|
test "the western chat presets use their own payload shape" {
  let msg = wb_message("error", 1700000000000UL)
  let slack = render_delivery(
    wb_target("slack", "https://hooks.slack.com/x"),
    msg,
    "host1",
  )
  assert_true(slack.body.contains("\"blocks\""))
  assert_true(slack.body.contains("\"mrkdwn\""))

  let discord = render_delivery(
    wb_target("discord", "https://discord.com/api/webhooks/x"),
    msg,
    "host1",
  )
  assert_true(discord.body.contains("\"embeds\""))
  assert_true(discord.body.contains("\"description\""))
}

///|
test "the generic preset and email carry a stable documented shape" {
  let msg = wb_message("warn", 1700000000000UL)
  let generic = render_delivery(
    wb_target("webhook", "https://gateway.example/hook", secret="tk"),
    msg,
    "host1",
  )
  assert_true(generic.body.contains("\"event\":\"crash\""))
  assert_true(generic.body.contains("\"level\":\"warn\""))
  assert_true(generic.body.contains("\"host\":\"host1\""))
  assert_true(
    generic.body.contains("\"fields\":{\"应用\":\"api\",\"端口\":\"3000\"}"),
  )
  assert_true(generic.headers.contains(("Authorization", "Bearer tk")))

  let email = render_delivery(
    wb_target(
      "email",
      "smtps://smtp.example:465",
      from="bm2@example.com",
      to=["ops@example.com", "oncall@example.com"],
      username="bm2@example.com",
      password="pw",
    ),
    msg,
    "host1",
  )
  let mail = email.mail.unwrap()
  assert_true(mail.contains("From: bm2@example.com"))
  assert_true(mail.contains("To: ops@example.com, oncall@example.com"))
  // The subject is RFC2047 encoded so non-ASCII titles survive SMTP.
  assert_true(mail.contains("Subject: =?UTF-8?B?"))
  assert_true(mail.contains("Date: Tue, 14 Nov 2023 22:13:20 +0000"))
  assert_true(mail.contains("\n\n**api · 实例异常退出**"))
}

///|
test "dedupe counts repeats and the rate limit drops the rest" {
  let policy = wb_policy(
    (
      #|[notify]
      #|enabled = true
      #|dedupe_window_s = 3600
      #|max_per_minute = 2
      #|queue_size = 8
      #|events = ["crash"]
      #|
      #|[[notify.target]]
      #|name = "t"
      #|preset = "webhook"
      #|url = "http://127.0.0.1:9/hook"
      #|
    ),
  )
  let notifier = wb_notifier("dedupe")
  assert_true(policy.enabled)
  // Same signature inside the window: queued once, the rest counted.
  notifier.emit(policy, "api", wb_message("warn", 1000UL))
  notifier.emit(policy, "api", wb_message("warn", 2000UL))
  notifier.emit(policy, "api", wb_message("warn", 3000UL))
  assert_eq(notifier.queue.length(), 1)
  // A different signature is a different event.
  notifier.emit(
    policy,
    "api",
    NotifyMessage::new("crash", "warn", "other", "body", "crash|api|1", 3000UL),
  )
  assert_eq(notifier.queue.length(), 2)
}

///|
test "rate limiting and queue overflow are counted, never unbounded" {
  let policy = wb_policy(
    (
      #|[notify]
      #|enabled = true
      #|dedupe_window_s = 0
      #|max_per_minute = 1
      #|queue_size = 2
      #|events = ["crash"]
      #|
      #|[[notify.target]]
      #|name = "t"
      #|preset = "webhook"
      #|url = "http://127.0.0.1:9/hook"
      #|
    ),
  )
  let notifier = wb_notifier("limit")
  notifier.emit(
    policy,
    "api",
    NotifyMessage::new("crash", "warn", "a", "b", "s1", 1000UL),
  )
  notifier.emit(
    policy,
    "api",
    NotifyMessage::new("crash", "warn", "a", "b", "s2", 1000UL),
  )
  notifier.emit(
    policy,
    "api",
    NotifyMessage::new("crash", "warn", "a", "b", "s3", 1000UL),
  )
  assert_eq(notifier.queue.length(), 2)
  assert_eq(notifier.dropped(), 1)
  // An unsubscribed event never queues at all.
  notifier.emit(
    policy,
    "api",
    NotifyMessage::new("report", "info", "r", "b", "s4", 1000UL),
  )
  assert_eq(notifier.queue.length(), 2)
  // Another project's events queue separately, with its own bound.
  notifier.emit(
    policy,
    "other",
    NotifyMessage::new("crash", "warn", "a", "b", "s5", 1000UL),
  )
  assert_eq(notifier.queue.length(), 3)
}

///|
test "per-target subscriptions and level floors are honoured" {
  let config = wb_policy(
    (
      #|[notify]
      #|enabled = true
      #|events = ["crash", "report"]
      #|
    ),
  )
  let quiet = wb_target("webhook", "http://127.0.0.1:9/a", min_level="error")
  let only_reports = wb_target("webhook", "http://127.0.0.1:9/b", events=[
    "report",
  ])
  let opted_out = wb_target("webhook", "http://127.0.0.1:9/c", report=false)
  assert_false(wants(quiet, config, wb_message("warn", 1000UL)))
  assert_true(wants(quiet, config, wb_message("error", 1000UL)))
  assert_false(wants(only_reports, config, wb_message("warn", 1000UL)))
  assert_true(
    wants(
      only_reports,
      config,
      NotifyMessage::new("report", "info", "r", "b", "s", 1000UL),
    ),
  )
  assert_false(
    wants(
      opted_out,
      config,
      NotifyMessage::new("report", "info", "r", "b", "s", 1000UL),
    ),
  )
}

///|
async test "a failed delivery reports a reason without the credential" {
  let policy = wb_policy(
    (
      #|[notify]
      #|enabled = true
      #|queue_size = 4
      #|events = ["crash"]
      #|
      #|[[notify.target]]
      #|name = "dead"
      #|preset = "webhook"
      #|url = "http://127.0.0.1:9/hook?token=SECRET"
      #|secret = "TOPSECRET"
      #|
    ),
  )
  let notifier = wb_notifier("fail")
  let results = notifier.deliver_now(
    policy.targets,
    policy.timeout_ms,
    None,
    NotifyMessage::new("crash", "warn", "t", "b", "s", 1000UL),
  )
  assert_eq(results.length(), 1)
  let (name, failure) = results[0]
  assert_eq(name, "dead")
  let reason = match failure {
    Some(reason) => reason
    None => fail("expected the unreachable target to fail")
  }
  assert_false(reason.is_empty())
  // Neither the URL, its token, nor the header credential may leak into a
  // reason that the CLI and the event log print.
  assert_false(reason.contains("SECRET"))
  assert_false(reason.contains("127.0.0.1"))
  assert_false(reason.contains("TOPSECRET"))
}

///|
test "chinese chat platforms are judged by their body code, not just http" {
  // 成功应答:错误码为 0。
  assert_true(
    body_failure("feishu", "{\"code\":0,\"msg\":\"success\"}") is None,
  )
  assert_true(
    body_failure("dingtalk", "{\"errcode\":0,\"errmsg\":\"ok\"}") is None,
  )
  assert_true(
    body_failure("wecom", "{\"errcode\":0,\"errmsg\":\"ok\"}") is None,
  )
  // token 或签名错误时,平台返回的是 200 + 非零错误码:必须算失败。
  let reason = match
    body_failure("feishu", "{\"code\":19021,\"msg\":\"sign match fail\"}") {
    Some(reason) => reason
    None => fail("expected the feishu error code to be reported")
  }
  assert_true(reason.contains("feishu"))
  assert_true(reason.contains("19021"))
  assert_true(reason.contains("sign match fail"))
  // 解析不了的应答(空 body、纯文本)不算失败,避免误报。
  assert_true(body_failure("dingtalk", "") is None)
  assert_true(body_failure("wecom", "ok") is None)
  // 非 domestic 平台没有响应体语义。
  assert_true(body_failure("webhook", "{\"error\":\"x\"}") is None)
}

///|
test "cpu percent needs a baseline before it reports anything" {
  let notifier = wb_notifier("cpu")
  let dir = "/tmp/bm2-notify-cpu-\{@process.get_pid()}"
  @process.mkdir_p(dir)
  let pid = @process.spawn({
    bun_path: "/bin/sh",
    script: "-c\u{0}i=0; while true; do i=$((i+1)); done",
    cwd: dir,
    out_log: "",
    err_log: "",
    env_blob: @process.base_env_blob(),
  })
  // First sample only sets the baseline: no percentage can be derived yet.
  assert_true(notifier.cpu_percent("k", pid, 1000UL) is None)
  @process.sleep_ms(300)
  match notifier.cpu_percent("k", pid, 1400UL) {
    Some(percent) => assert_true(percent >= 0.0)
    None => fail("expected a cpu percentage once a baseline exists")
  }
  @process.discard(() => @process.kill_group(pid, @process.SIGKILL))
  @process.drain_child(pid)
}
