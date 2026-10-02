///|
/// 纯内存的拓扑排序测试:不依赖真实 workspace 布局,任何 cwd 下都可复现。
/// 真实布局的正确性由 dry-run(e2e)覆盖。
test "topo orders dependencies before dependents" {
  let notify_member : Member = {
    dir: "notify",
    name: "chensuiyi/notify",
    version: "0.1.0",
    imports: [],
  }
  let bm2_member : Member = {
    dir: "bm2",
    name: "chensuiyi/bm2",
    version: "0.4.1",
    imports: ["chensuiyi/notify"],
  }
  let selected = [notify_member, bm2_member]
  let order = topo_sort(selected, [notify_member, bm2_member])
  assert_eq(order.length(), 2)
  assert_eq(order[0].name, "chensuiyi/notify")
  assert_eq(order[1].name, "chensuiyi/bm2")
}
