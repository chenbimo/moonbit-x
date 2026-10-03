///|
test "trim_spaces/both_ends" {
  assert_eq(trim_spaces("  hello world  "), "hello world")
}

///|
test "trim_spaces/tabs_and_crlf" {
  assert_eq(trim_spaces("\t\tx\r"), "x")
  assert_eq(trim_spaces(" \t "), "")
}

///|
test "trim_spaces/nothing_to_do" {
  assert_eq(trim_spaces("intact"), "intact")
}

///|
test "parse_int/strict_digits" {
  assert_eq(parse_int("42"), Some(42))
  assert_eq(parse_int("0"), Some(0))
  assert_eq(parse_int("007"), Some(7))
}

///|
test "parse_int/rejects_partial" {
  assert_eq(parse_int("4x"), None)
  assert_eq(parse_int("-1"), None)
  assert_eq(parse_int(""), None)
}

///|
test "quoted_value/manifest_line" {
  assert_eq(quoted_value("name = \"chensuiyi/bm2\""), "chensuiyi/bm2")
  assert_eq(quoted_value("version = \"0.5.0\" # comment"), "0.5.0")
}

///|
test "quoted_value/unquoted_is_empty" {
  assert_eq(quoted_value("no quotes here"), "")
}

///|
test "json_escape/control_and_quotes" {
  assert_eq(json_escape("a\"b\\c\nd\te"), "a\\\"b\\\\c\\nd\\te")
  assert_eq(json_escape("\u{01}"), "\\u0001")
}

///|
test "jstr/wraps_and_escapes" {
  assert_eq(jstr("say \"hi\""), "\"say \\\"hi\\\"\"")
}

///|
test "jobj/optional_keys_vanish" {
  // Absent optional fields simply are not in the input array, so they never
  // become nulls on the wire.
  assert_eq(jobj([]), "{}")
  assert_eq(jobj([("a", jstr("1")), ("n", "42")]), "{\"a\":\"1\",\"n\":42}")
}

///|
test "jarr/fragments" {
  assert_eq(jarr([]), "[]")
  assert_eq(jarr([jstr("x"), "1"]), "[\"x\",1]")
}

///|
test "url_encode/unreserved_pass_through" {
  assert_eq(url_encode("aB9-._~"), "aB9-._~")
}

///|
test "url_encode/specials_and_multibyte" {
  assert_eq(url_encode("a b&c=1"), "a%20b%26c%3D1")
  assert_eq(url_encode("中"), "%E4%B8%AD")
}
