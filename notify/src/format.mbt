///|
/// Text and encoding helpers shared by the platform presets: JSON escaping,
/// percent-encoding, request signing and the two body layouts every message is
/// rendered from.

///|
const HEX_DIGITS : String = "0123456789ABCDEF"

///|
fn hex_pair(value : Int) -> String {
  let high = value >> 4
  let low = value & 15
  HEX_DIGITS[high:high + 1].to_owned() + HEX_DIGITS[low:low + 1].to_owned()
}

///|
fn json_escape(text : String) -> String {
  let buf = StringBuilder()
  for c in text {
    match c {
      '"' => buf.write_string("\\\"")
      '\\' => buf.write_string("\\\\")
      '\n' => buf.write_string("\\n")
      '\r' => buf.write_string("\\r")
      '\t' => buf.write_string("\\t")
      _ =>
        if c.to_int() < 0x20 {
          buf.write_string("\\u00" + hex_pair(c.to_int()))
        } else {
          buf.write_char(c)
        }
    }
  }
  buf.to_string()
}

///|
fn jstr(text : String) -> String {
  "\"" + json_escape(text) + "\""
}

///|
/// Build a JSON object from already-encoded value fragments, so an optional key
/// simply does not appear instead of turning into a null the platform may
/// reject.
fn jobj(fields : Array[(String, String)]) -> String {
  let buf = StringBuilder()
  buf.write_char('{')
  let mut first = true
  for pair in fields {
    let (key, value) = pair
    if !first {
      buf.write_char(',')
    }
    first = false
    buf.write_string(jstr(key))
    buf.write_char(':')
    buf.write_string(value)
  }
  buf.write_char('}')
  buf.to_string()
}

///|
fn jarr(items : Array[String]) -> String {
  let buf = StringBuilder()
  buf.write_char('[')
  let mut first = true
  for item in items {
    if !first {
      buf.write_char(',')
    }
    first = false
    buf.write_string(item)
  }
  buf.write_char(']')
  buf.to_string()
}

///|
fn is_unreserved(value : Int) -> Bool {
  (value >= 48 && value <= 57) ||
  (value >= 65 && value <= 90) ||
  (value >= 97 && value <= 122) ||
  value == 45 ||
  value == 46 ||
  value == 95 ||
  value == 126
}

///|
/// Percent-encode a value for a URL query string or a form body.
fn url_encode(text : String) -> String {
  let buf = StringBuilder()
  for byte in @utf8.encode(text) {
    let value = byte.to_int()
    if is_unreserved(value) {
      // Unreserved bytes are ASCII, so decoding one byte back gives the char.
      buf.write_string(@utf8.decode_lossy(Bytes::from_array([byte])))
    } else {
      buf.write_char('%')
      buf.write_string(hex_pair(value))
    }
  }
  buf.to_string()
}

///|
/// HMAC-SHA256, base64-encoded: the shared half of the two Chinese chat
/// platforms' request signing.
fn hmac_sha256_base64(key : String, message : String) -> String {
  let mac = @crypto.hmac(
    @crypto.SHA256::new(),
    @utf8.encode(key)[:],
    @utf8.encode(message)[:],
  )
  @base64.encode(mac.unsafe_reinterpret_as_bytes())
}

///|
/// DingTalk signs `timestamp + "\n" + secret` with the secret as the key, and
/// carries the timestamp in milliseconds.
fn dingtalk_signature(secret : String, timestamp_ms : UInt64) -> String {
  url_encode(
    hmac_sha256_base64(secret, timestamp_ms.to_string() + "\n" + secret),
  )
}

///|
/// Feishu signs the *empty* message with `timestamp + "\n" + secret` as the key
/// (the inverse of DingTalk) and carries the timestamp in seconds.
fn feishu_signature(secret : String, timestamp_s : UInt64) -> String {
  hmac_sha256_base64(timestamp_s.to_string() + "\n" + secret, "")
}

///|
fn field_lines(msg : Message, bullet : String) -> String {
  let buf = StringBuilder()
  for pair in msg.fields {
    let (key, value) = pair
    buf.write_string("\n" + bullet + key + ": " + value)
  }
  buf.to_string()
}

///|
fn plain_body(msg : Message, ctx : Context) -> String {
  msg.title +
  "\n" +
  msg.body +
  field_lines(msg, "") +
  "\n\n--\n" +
  ctx.product +
  " @ " +
  ctx.host
}

///|
fn markdown_body(msg : Message, ctx : Context) -> String {
  "**" +
  msg.title +
  "**\n\n" +
  msg.body +
  field_lines(msg, "- ") +
  "\n\n> " +
  ctx.product +
  " @ " +
  ctx.host
}

///|
/// Two decimal digits at a known offset of an ASCII string. Used only on the
/// ISO timestamp produced by `iso8601`, so byte and char offsets coincide.
fn two_digits(text : String, start : Int) -> Int {
  let mut value = 0
  let mut index = 0
  for c in text {
    if index >= start && index < start + 2 {
      value = value * 10 + c.to_int() - 48
    }
    index += 1
  }
  value
}

///|
/// Format epoch milliseconds as an ISO 8601 UTC timestamp
/// (civil-from-days algorithm, Howard Hinnant, public domain).
fn iso8601(epoch_ms : UInt64) -> String {
  let ms = epoch_ms % 1000UL
  let secs = epoch_ms / 1000UL
  let days = secs / 86400UL
  let rem = secs % 86400UL
  let z = days + 719468UL
  let era = z / 146097UL
  let doe = z - era * 146097UL
  let yoe = (doe - doe / 1460UL + doe / 36524UL - doe / 146096UL) / 365UL
  let y0 = yoe + era * 400UL
  let doy = doe - (365UL * yoe + yoe / 4UL - yoe / 100UL)
  let mp = (5UL * doy + 2UL) / 153UL
  let day = doy - (153UL * mp + 2UL) / 5UL + 1UL
  let month = if mp < 10UL { mp + 3UL } else { mp - 9UL }
  let year = if month <= 2UL { y0 + 1UL } else { y0 }
  pad4(year) +
  "-" +
  pad2(month) +
  "-" +
  pad2(day) +
  "T" +
  pad2(rem / 3600UL) +
  ":" +
  pad2(rem % 3600UL / 60UL) +
  ":" +
  pad2(rem % 60UL) +
  "." +
  pad3(ms) +
  "Z"
}

///|
fn pad2(n : UInt64) -> String {
  if n < 10UL {
    "0" + n.to_string()
  } else {
    n.to_string()
  }
}

///|
fn pad3(n : UInt64) -> String {
  if n < 10UL {
    "00" + n.to_string()
  } else if n < 100UL {
    "0" + n.to_string()
  } else {
    n.to_string()
  }
}

///|
fn pad4(n : UInt64) -> String {
  if n < 1000UL {
    "0" + pad3(n)
  } else {
    n.to_string()
  }
}

///|
/// `Tue, 29 Sep 2026 10:00:00 +0000` — email needs the weekday and month names
/// spelled out, which the ISO timestamp used everywhere else does not carry.
fn rfc5322_date(epoch_ms : UInt64) -> String {
  let weekdays = ["Thu", "Fri", "Sat", "Sun", "Mon", "Tue", "Wed"]
  let months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov",
    "Dec",
  ]
  let iso = iso8601(epoch_ms)
  let days = epoch_ms / 1000UL / 86400UL
  weekdays[(days % 7UL).to_int()] +
  ", " +
  iso[8:10].to_owned() +
  " " +
  months[two_digits(iso, 5) - 1] +
  " " +
  iso[:4].to_owned() +
  " " +
  iso[11:19].to_owned() +
  " +0000"
}
