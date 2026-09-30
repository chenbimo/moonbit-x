///|
/// The `[notify]` section is part of bm2.toml, so it is rejected or accepted by
/// the same project parse the CLI and the daemon use. Notification settings get
/// the same treatment as the rest of the file: closed sets, explicit bounds, and
/// messages that name the field without ever echoing a credential.

///|
/// One project document with the given notification section appended, so each
/// case exercises the real parse path rather than a parser of its own.
fn project_doc(notify_section : String) -> String {
  "name = \"blog\"\nscript = \"index.ts\"\ninstances = 1\nport = 3000\n" +
  notify_section
}

///|
fn notify_error(notify_section : String) -> String raise {
  parse_error(project_doc(notify_section))
}

///|
test "parses a notify section with several targets" {
  let config = @config.parse(
    project_doc(
      (
        #|[notify]
        #|enabled = true
        #|timeout_ms = 3000
        #|dedupe_window_s = 60
        #|max_per_minute = 10
        #|queue_size = 32
        #|events = ["crash", "errored", "report"]
        #|report_interval_min = 30
        #|report_fields = ["status", "rss", "cpu"]
        #|include_log_lines = 5
        #|threshold_rss_percent = 80
        #|threshold_offline_min = 5
        #|threshold_restarts = 3
        #|
        #|[[notify.target]]
        #|name = "飞书-运维群"
        #|preset = "feishu"
        #|url = "https://open.feishu.cn/open-apis/bot/v2/hook/xxx"
        #|secret = "sign-key"
        #|
        #|[[notify.target]]
        #|name = "邮件-值班"
        #|preset = "email"
        #|url = "smtps://smtp.example:465"
        #|from = "bm2@example.com"
        #|to = ["ops@example.com", "oncall@example.com"]
        #|username = "bm2@example.com"
        #|password = "pw"
        #|min_level = "warn"
        #|report = false
        #|
      ),
    ),
    "/srv/yicode",
  )
  let notify = config.notify
  assert_true(notify.enabled)
  assert_eq(notify.timeout_ms, 3000)
  assert_eq(notify.dedupe_window_s, 60)
  assert_eq(notify.events.length(), 3)
  assert_eq(notify.report_interval_min, 30)
  assert_eq(notify.threshold_restarts, 3)
  assert_eq(notify.targets.length(), 2)
  assert_eq(notify.targets[0].name, "飞书-运维群")
  assert_eq(notify.targets[0].secret, Some("sign-key"))
  assert_eq(notify.targets[1].to.unwrap().length(), 2)
  assert_eq(notify.targets[1].min_level, Some("warn"))
  assert_eq(notify.targets[1].report, Some(false))
}

///|
/// A project that never writes a `[notify]` section reports nothing, which is
/// the state every existing bm2.toml is in.
test "a project without a notify section reports nothing" {
  let config = @config.parse(project_doc(""), "/srv/yicode")
  assert_false(config.notify.enabled)
  assert_eq(config.notify.targets.length(), 0)
}

///|
test "notify rejects unknown keys, presets and enum values" {
  assert_true(
    notify_error("[notify]\nenabled = true\nnope = 1\n").contains(
      "unknown field nope",
    ),
  )
  assert_true(
    notify_error(
      "[notify]\nenabled = true\n\n[[notify.target]]\nname = \"a\"\npreset = \"carrier-pigeon\"\nurl = \"https://x/y\"\n",
    ).contains("unknown value carrier-pigeon"),
  )
  assert_true(
    notify_error("[notify]\nevents = [\"explode\"]\n").contains(
      "unknown value explode",
    ),
  )
  assert_true(
    notify_error(
      "[notify]\n\n[[notify.target]]\nname = \"a\"\npreset = \"webhook\"\nurl = \"https://x/y\"\nformat = \"pdf\"\n",
    ).contains("unknown value pdf"),
  )
  assert_true(
    notify_error(
      "[notify]\n\n[[notify.target]]\nname = \"a\"\npreset = \"webhook\"\nurl = \"https://x/y\"\nmin_level = \"fatal\"\n",
    ).contains("unknown value fatal"),
  )
  assert_true(
    notify_error("[notify]\nreport_fields = [\"latency\"]\n").contains(
      "unknown value latency",
    ),
  )
  assert_true(
    notify_error("[notify]\ntimeout_ms = 10\n").contains(
      "notify.timeout_ms must be between",
    ),
  )
  assert_true(
    notify_error("[notify]\nqueue_size = 0\n").contains(
      "notify.queue_size must be between",
    ),
  )
}

///|
test "notify enforces per-preset required fields" {
  // Web presets need an http(s) endpoint; email needs smtp and an envelope.
  assert_true(
    notify_error(
      "[notify]\n\n[[notify.target]]\nname = \"a\"\npreset = \"webhook\"\nurl = \"smtp://x:25\"\n",
    ).contains("must start with one of"),
  )
  assert_true(
    notify_error(
      "[notify]\n\n[[notify.target]]\nname = \"a\"\npreset = \"email\"\nurl = \"https://x/y\"\nfrom = \"a@b.c\"\nto = [\"d@e.f\"]\n",
    ).contains("must start with one of"),
  )
  assert_true(
    notify_error(
      "[notify]\n\n[[notify.target]]\nname = \"a\"\npreset = \"email\"\nurl = \"smtps://x:465\"\nto = [\"d@e.f\"]\n",
    ).contains("from is required"),
  )
  assert_true(
    notify_error(
      "[notify]\n\n[[notify.target]]\nname = \"a\"\npreset = \"email\"\nurl = \"smtps://x:465\"\nfrom = \"a@b.c\"\n",
    ).contains("to is required"),
  )
  assert_true(
    notify_error(
      "[notify]\n\n[[notify.target]]\nname = \"a\"\npreset = \"pushover\"\nurl = \"https://api.pushover.net/1/messages.json\"\n",
    ).contains("unknown value pushover"),
  )
  // Fields that belong to another preset are rejected rather than ignored.
  assert_true(
    notify_error(
      "[notify]\n\n[[notify.target]]\nname = \"a\"\npreset = \"webhook\"\nurl = \"https://x/y\"\npassword = \"pw\"\n",
    ).contains("password is not used"),
  )
  assert_true(
    notify_error(
      "[notify]\n\n[[notify.target]]\nname = \"a\"\npreset = \"webhook\"\nurl = \"https://x/y\"\nto = [\"d@e.f\"]\n",
    ).contains("to is not used"),
  )
  assert_true(
    notify_error(
      "[notify]\n\n[[notify.target]]\nname = \"a\"\npreset = \"webhook\"\nurl = \"https://x/y\"\n\n[[notify.target]]\nname = \"a\"\npreset = \"slack\"\nurl = \"https://x/z\"\n",
    ).contains("duplicate target name"),
  )
}

///|
/// The CLI and the event log print these messages verbatim, so a rejected
/// target must be identifiable by index without leaking what it points at or
/// what it authenticates with.
test "notify errors never echo a url, secret or password" {
  let message = notify_error(
    (
      #|[notify]
      #|
      #|[[notify.target]]
      #|name = "leaky"
      #|preset = "carrier-pigeon"
      #|url = "https://gateway.example/hook?token=URLSECRET"
      #|secret = "TOPSECRET"
      #|password = "PASSSECRET"
      #|
    ),
  )
  assert_true(message.contains("notify.target[0]"))
  assert_false(message.contains("URLSECRET"))
  assert_false(message.contains("TOPSECRET"))
  assert_false(message.contains("PASSSECRET"))
  assert_false(message.contains("gateway.example"))
}
