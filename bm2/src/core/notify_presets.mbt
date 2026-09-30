///|
/// Platform presets: every difference between the supported notification
/// platforms lives in the `match` below, and each arm describes only the
/// payload shape, where the credential goes and how the request is signed.
/// Adding a platform means adding one arm plus one row in the README table —
/// nothing else in bm2 knows that platforms exist.

///|
fn default_format(preset : String) -> String {
  match preset {
    "slack" | "discord" | "feishu" | "dingtalk" | "wecom" => "markdown"
    _ => "text"
  }
}

///|
/// Render one message for one target: endpoint (any signature already folded
/// in), headers, body, and — for email — the whole RFC5322 message the
/// transport uploads through curl.
fn render_delivery(
  target : @config.NotifyTarget,
  msg : NotifyMessage,
  host : String,
) -> Delivery raise NotifyError {
  let format = target.format.unwrap_or(default_format(target.preset))
  match target.preset {
    "feishu" => render_feishu(target, msg, host, format)
    "dingtalk" => render_dingtalk(target, msg, host, format)
    "wecom" => render_wecom(target, msg, host, format)
    "slack" => render_slack(target, msg, host, format)
    "discord" => render_discord(target, msg, host, format)
    "webhook" => render_generic(target, msg, host, format)
    "email" => render_email(target, msg, host, format)
    _ => raise NotifyError::InvalidPreset(target.preset)
  }
}

///|
fn json_delivery(
  url : String,
  body : String,
  headers : Array[(String, String)],
) -> Delivery {
  {
    url,
    http_method: "POST",
    content_type: Some("application/json; charset=utf-8"),
    headers,
    body,
    mail: None,
  }
}

///|
fn render_feishu(
  target : @config.NotifyTarget,
  msg : NotifyMessage,
  host : String,
  format : String,
) -> Delivery {
  let fields : Array[(String, String)] = []
  if format == "markdown" || format == "card" {
    fields.push(("msg_type", jstr("interactive")))
    fields.push(
      (
        "card",
        jobj([
          (
            "elements",
            jarr([
              jobj([
                ("tag", jstr("div")),
                (
                  "text",
                  jobj([
                    ("tag", jstr("lark_md")),
                    ("content", jstr(markdown_body(msg, host))),
                  ]),
                ),
              ]),
            ]),
          ),
        ]),
      ),
    )
  } else {
    fields.push(("msg_type", jstr("text")))
    fields.push(("content", jobj([("text", jstr(plain_body(msg, host)))])))
  }
  match target.secret {
    Some(secret) =>
      if !secret.is_empty() {
        let seconds = msg.ts_ms / 1000UL
        fields.push(("timestamp", jstr(seconds.to_string())))
        fields.push(("sign", jstr(feishu_signature(secret, seconds))))
      }
    None => ()
  }
  json_delivery(target.url, jobj(fields), [])
}

///|
fn render_dingtalk(
  target : @config.NotifyTarget,
  msg : NotifyMessage,
  host : String,
  format : String,
) -> Delivery {
  let body = if format == "markdown" || format == "card" {
    jobj([
      ("msgtype", jstr("markdown")),
      (
        "markdown",
        jobj([
          ("title", jstr(msg.title)),
          ("text", jstr(markdown_body(msg, host))),
        ]),
      ),
    ])
  } else {
    jobj([
      ("msgtype", jstr("text")),
      ("text", jobj([("content", jstr(plain_body(msg, host)))])),
    ])
  }
  let mut url = target.url
  match target.secret {
    Some(secret) =>
      if !secret.is_empty() {
        url = url +
          (if url.contains("?") { "&" } else { "?" }) +
          "timestamp=" +
          msg.ts_ms.to_string() +
          "&sign=" +
          dingtalk_signature(secret, msg.ts_ms)
      }
    None => ()
  }
  json_delivery(url, body, [])
}

///|
fn render_wecom(
  target : @config.NotifyTarget,
  msg : NotifyMessage,
  host : String,
  format : String,
) -> Delivery {
  let body = if format == "markdown" || format == "card" {
    jobj([
      ("msgtype", jstr("markdown")),
      ("markdown", jobj([("content", jstr(markdown_body(msg, host)))])),
    ])
  } else {
    jobj([
      ("msgtype", jstr("text")),
      ("text", jobj([("content", jstr(plain_body(msg, host)))])),
    ])
  }
  json_delivery(target.url, body, [])
}

///|
fn render_slack(
  target : @config.NotifyTarget,
  msg : NotifyMessage,
  host : String,
  format : String,
) -> Delivery {
  let body = if format == "card" || format == "markdown" {
    jobj([
      ("text", jstr(msg.title)),
      (
        "blocks",
        jarr([
          jobj([
            ("type", jstr("section")),
            (
              "text",
              jobj([
                ("type", jstr("mrkdwn")),
                ("text", jstr(markdown_body(msg, host))),
              ]),
            ),
          ]),
        ]),
      ),
    ])
  } else {
    jobj([("text", jstr(markdown_body(msg, host)))])
  }
  json_delivery(target.url, body, [])
}

///|
fn render_discord(
  target : @config.NotifyTarget,
  msg : NotifyMessage,
  host : String,
  format : String,
) -> Delivery {
  let body = if format == "card" || format == "markdown" {
    jobj([
      ("content", jstr(msg.title)),
      (
        "embeds",
        jarr([
          jobj([
            ("title", jstr(msg.title)),
            ("description", jstr(markdown_body(msg, host))),
          ]),
        ]),
      ),
    ])
  } else {
    jobj([("content", jstr(markdown_body(msg, host)))])
  }
  json_delivery(target.url, body, [])
}

///|
/// The generic preset: one stable, documented JSON shape for everything bm2
/// does not ship a preset for (self-hosted gateways, other webhook platforms).
fn render_generic(
  target : @config.NotifyTarget,
  msg : NotifyMessage,
  host : String,
  format : String,
) -> Delivery {
  ignore(format)
  let body = jobj([
    ("event", jstr(msg.event)),
    ("level", jstr(msg.level)),
    ("title", jstr(msg.title)),
    ("body", jstr(msg.body)),
    ("host", jstr(host)),
    ("timestamp", jstr(msg.ts_ms.to_string())),
    ("fields", jobj(json_pairs(msg.fields))),
  ])
  let headers = []
  match target.secret {
    Some(secret) =>
      if !secret.is_empty() {
        headers.push(("Authorization", "Bearer " + secret))
      }
    None => ()
  }
  json_delivery(target.url, body, headers)
}

///|
fn json_pairs(fields : Array[(String, String)]) -> Array[(String, String)] {
  fields.map(fn(pair) {
    let (key, value) = pair
    (key, jstr(value))
  })
}

///|
/// Email is the one preset whose transport is SMTP, so it renders a whole
/// message (headers plus UTF-8 body) for curl to upload.
fn render_email(
  target : @config.NotifyTarget,
  msg : NotifyMessage,
  host : String,
  format : String,
) -> Delivery {
  ignore(format)
  let buf = StringBuilder()
  buf.write_string("From: " + target.from.unwrap_or("") + "\n")
  buf.write_string("To: " + target.to.unwrap_or([]).join(", ") + "\n")
  buf.write_string(
    "Subject: =?UTF-8?B?" + @base64.encode(@utf8.encode(msg.title)[:]) + "?=\n",
  )
  buf.write_string("Date: " + rfc5322_date(msg.ts_ms) + "\n")
  buf.write_string("MIME-Version: 1.0\n")
  buf.write_string("Content-Type: text/plain; charset=UTF-8\n")
  buf.write_string("Content-Transfer-Encoding: 8bit\n")
  buf.write_string("X-Bm2-Host: " + host + "\n")
  buf.write_string("\n")
  buf.write_string(markdown_body(msg, host))
  buf.write_string("\n")
  {
    url: target.url,
    http_method: "POST",
    content_type: None,
    headers: [],
    body: "",
    mail: Some(buf.to_string()),
  }
}
