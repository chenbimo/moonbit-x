///|
fn wb_setup(root : String, port : Int) -> Supervisor raise {
  @fsx.mkdir_p(root)
  let config : @config.Config = {
    name: "wbapp",
    cwd: root,
    script: "x.sh",
    runtime: "bun",
    exec_mode: "fork",
    instances: 1,
    port,
    max_memory_mb: 512,
    max_restarts: 2,
    restart_delay_ms: 100,
    min_uptime_ms: 60000,
    stop_timeout_ms: 200,
    notify: @config.NotifyConfig::disabled(),
    env: [],
  }
  let sv = Supervisor::new(state_dir=root + "/state", bun_path="/bin/sh")
  sv.register(config, root + "/bm2.toml")
  sv
}

///|
test "spawn failures back off and exhaust the budget into errored" {
  let root = "/tmp/bm2-wbtest-spawn-\{@subproc.get_pid()}"
  let sv = wb_setup(root, 4451)
  let inst = sv.instance("wbapp", 0)
  sv.mark_spawn_failed(inst)
  assert_true(inst.status is Restarting)
  assert_eq(inst.restart_count, 1)
  let first_wait = inst.restart_at_ms - @dateku.now_ms()
  assert_true(first_wait > 0UL)
  sv.mark_spawn_failed(inst)
  assert_eq(inst.restart_count, 2)
  // The backoff grows with the retry count: delay * restart_count.
  assert_true(inst.restart_at_ms - @dateku.now_ms() >= first_wait)
  sv.mark_spawn_failed(inst)
  assert_true(inst.status is Errored)
  assert_eq(inst.restart_at_ms, 0UL)
  let crash = @fs.read_file_to_string(
    root + "/state/wbapp/logs/wbapp-0.crash.log",
  )
  assert_true(crash.contains("reason=spawn_failed"))
  assert_true(crash.contains("restartCount=3"))
}

///|
test "rotate_logs rotates oversized app logs with copytruncate" {
  let root = "/tmp/bm2-wbtest-rotate-\{@subproc.get_pid()}"
  let sv = wb_setup(root, 4452)
  let base = root + "/state/wbapp/logs/wbapp-0"
  // 11 MB exceeds the 10 MB rotation threshold.
  @fsx.append_file(base + ".out.log", Bytes::make(11 * 1024 * 1024, b'x'))
  @fsx.append_file(base + ".crash.log", @utf8.encode("small\n"))
  sv.rotate_logs()
  match @fsx.file_size(base + ".out.log.1") {
    Some(size) => assert_true(size > 10L * 1024L * 1024L)
    None => fail("expected rotated generation .out.log.1")
  }
  assert_eq(@fsx.file_size(base + ".out.log"), Some(0L))
  assert_false(@fs.path_exists(base + ".crash.log.1"))
}

///|
async test "wait_settled gives up after the deadline" {
  let root = "/tmp/bm2-wbtest-settle-\{@subproc.get_pid()}"
  let sv = wb_setup(root, 4453)
  let inst = sv.instance("wbapp", 0)
  inst.status = Restarting
  inst.pid = 0
  inst.restart_at_ms = @dateku.now_ms() + 60000UL
  assert_false(sv.wait_settled(["wbapp"]))
}

///|
/// OOM attribution: SIGKILL with the last sample near the limit; anything
/// else (other signals, low-RSS kills, missing samples) stays a plain crash.
test "oom kill attribution needs signal 9 and a near-limit sample" {
  // 100 MB limit = 102400 kB; the 90% boundary is 92160 kB.
  // Signal 9 at 95% of the limit.
  assert_eq(is_oom_kill(Some(9), 97280, 100), true)
  // Exactly at the 90% boundary counts.
  assert_eq(is_oom_kill(Some(9), 92160, 100), true)
  // Below the boundary is a plain crash.
  assert_eq(is_oom_kill(Some(9), 90000, 100), false)
  // Other signals and unknown exits never attribute to the OOM killer.
  assert_eq(is_oom_kill(Some(15), 99000, 100), false)
  assert_eq(is_oom_kill(None, 99000, 100), false)
  // An instance never sampled has last_rss_kb 0.
  assert_eq(is_oom_kill(Some(9), 0, 100), false)
}

///|
/// Storm counting only looks inside the window and prunes what fell out.
test "storm window counts recent restarts and prunes old ones" {
  let hits : Array[UInt64] = [1000UL, 2000UL, 9000UL]
  // Window 5s at t=10000: only t=9000 is inside; the rest is pruned.
  assert_eq(storm_hit_count(hits, 10000UL, 5000UL), 1)
  assert_eq(hits.length(), 1)
  // A later pass over the pruned array keeps the count stable while the
  // entry is still inside the window.
  assert_eq(storm_hit_count(hits, 12000UL, 5000UL), 1)
}
