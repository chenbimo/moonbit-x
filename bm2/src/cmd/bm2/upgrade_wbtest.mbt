///|
/// The upgrade path: read the published version out of the mooncakes index
/// and compare it with the running one through the shared comparator.
test "latest_version returns the last parseable line" {
  let index = "{\"version\":\"0.1.0\"}\n{\"version\":\"0.2.0\"}\n{\"version\":\"0.2.2\"}\n"
  assert_eq(latest_version(index), Some("0.2.2"))
  assert_eq(latest_version("garbage\n{\"version\":\"0.2.2\"}"), Some("0.2.2"))
  assert_eq(latest_version("not json"), None)
  assert_eq(latest_version(""), None)
}

///|
test "upgrade only fires when the published version is newer" {
  let index = "{\"version\":\"0.5.0\"}\n{\"version\":\"0.5.1\"}\n"
  let latest = match latest_version(index) {
    Some(version) => version
    None => fail("expected a published version")
  }
  // 索引里最新的是 0.5.1,比当前 0.5.0 新:升级应触发。
  assert_true(
    @semver.compare(@semver.parse(latest), @semver.parse(VERSION)) > 0,
  )
  assert_true(
    @semver.compare(@semver.parse("0.5.2"), @semver.parse(VERSION)) > 0,
  )
  assert_true(
    @semver.compare(@semver.parse("0.4.9"), @semver.parse(VERSION)) < 0,
  )
}
