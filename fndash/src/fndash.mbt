///|
/// Strip spaces and tabs from both ends (plus a trailing CR, so Windows
/// line endings survive a `split("\n")`).
pub fn trim_spaces(text : StringView) -> String {
  let mut start = 0
  let end = text.length()
  while start < end {
    let ch = text[start].to_int()
    if ch == 0x20 || ch == 0x09 {
      start += 1
    } else {
      break
    }
  }
  let mut stop = end
  while stop > start {
    let ch = text[stop - 1].to_int()
    if ch == 0x20 || ch == 0x09 || ch == 0x0D {
      stop -= 1
    } else {
      break
    }
  }
  if start == 0 && stop == end {
    text.to_owned()
  } else if start >= stop {
    ""
  } else {
    text[start:stop].to_owned()
  }
}

///|
/// Strict non-negative integer: every character must be an ASCII digit,
/// empty input rejected. Returns `None` instead of a partial number.
pub fn parse_int(text : String) -> Int? {
  if text.is_empty() {
    return None
  }
  let mut value = 0
  for i in 0..<text.length() {
    let ch = text[i].to_int()
    if ch < 0x30 || ch > 0x39 {
      return None
    }
    value = value * 10 + (ch - 0x30)
  }
  Some(value)
}

///|
/// Text of the first double-quoted segment in a line, or `""` when the
/// line quotes nothing. Built for `key = "value"` manifest lines.
pub fn quoted_value(line : String) -> String {
  let mut start = -1
  let mut stop = line.length()
  for i, ch in line {
    if ch == '"' {
      if start < 0 {
        start = i
      } else {
        stop = i
        break
      }
    }
  }
  if start >= 0 && stop > start {
    line[start + 1:stop].to_owned()
  } else {
    ""
  }
}

///|
const HEX_DIGITS : String = "0123456789ABCDEF"

///|
fn hex_pair(value : Int) -> String {
  let high = value >> 4
  let low = value & 15
  HEX_DIGITS[high:high + 1].to_owned() + HEX_DIGITS[low:low + 1].to_owned()
}

///|
/// Escape a string for embedding inside a JSON double-quoted literal:
/// quotes, backslashes and the C/JSON control escapes; other control
/// characters become `\u00XX`.
pub fn json_escape(text : String) -> String {
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
/// A JSON string literal: the text, escaped and wrapped in quotes.
pub fn jstr(text : String) -> String {
  "\"" + json_escape(text) + "\""
}

///|
/// Build a JSON object from already-encoded value fragments, so an optional
/// key simply does not appear instead of turning into a null the platform
/// may reject. Keys are quoted by `jstr`; values must arrive pre-encoded
/// (e.g. `jstr(...)` for strings, raw digits for numbers).
pub fn jobj(fields : Array[(String, String)]) -> String {
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
/// Build a JSON array from already-encoded item fragments.
pub fn jarr(items : Array[String]) -> String {
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
/// Percent-encode a value for a URL query string or a form body: everything
/// outside the RFC 3986 unreserved set becomes `%XX` over UTF-8 bytes.
pub fn url_encode(text : String) -> String {
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
