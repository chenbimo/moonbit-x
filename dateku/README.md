# chensuiyi/dateku

Epoch-millisecond timestamps for MoonBit: ISO 8601 / RFC 5322 formatting, UTC component access, construction, shifts, and calendar queries. UTC only.

## Install

```bash
moon add chensuiyi/dateku
```

## Features

- `iso8601` / `rfc5322`: civil-from-days algorithm; leap-century rules and millisecond boundaries tested
- Components: `year` / `month` / `day` / `hour` / `minute` / `second` / `millisecond`
- `make_epoch`: construct from UTC parts; out-of-range components roll over; the exact inverse of `iso8601`
- Shifts: `add_days` / `add_hours` / `add_minutes` / `add_seconds` (negative shifts backwards)
- Day queries: `start_of_day` / `is_same_day`; calendar: `is_leap_year` / `days_in_month`
- Deliberately out of scope: timezones, localization, parsing

## Scenarios

- Log line timestamps (ISO 8601)
- Email `Date` headers (RFC 5322)
- Status lines and TTL windows: shift by hours/days, test same-day

## API

| Function | Description |
| --- | --- |
| `now_ms()` | Current epoch milliseconds |
| `now_unix()` | Current epoch seconds |
| `iso8601(epoch_ms)` | `2026-10-03T08:15:30.123Z` |
| `rfc5322(epoch_ms)` | `Sat, 03 Oct 2026 08:15:30 +0000` |
| `year(epoch_ms)` | UTC year |
| `month(epoch_ms)` | UTC month, 1-12 |
| `day(epoch_ms)` | UTC day of month, 1-31 |
| `hour(epoch_ms)` | UTC hour, 0-23 |
| `minute(epoch_ms)` | UTC minute, 0-59 |
| `second(epoch_ms)` | UTC second, 0-59 |
| `millisecond(epoch_ms)` | UTC millisecond, 0-999 |
| `make_epoch(y, m, d, ...)` | Construct epoch ms; parts roll over |
| `is_leap_year(y)` | Gregorian leap year |
| `days_in_month(y, m)` | 28-31, 0 for invalid month |
| `add_days / add_hours / add_minutes / add_seconds(e, n)` | Shift, negative = backwards |
| `start_of_day(e)` | UTC midnight of that day |
| `is_same_day(a, b)` | Same UTC day |

<details>
<summary><strong>用法示例 / usage</strong></summary>

```moonbit
@dateku.iso8601(1791015330123UL)   // "2026-10-03T08:15:30.123Z"
@dateku.rfc5322(1791015330000UL)   // "Sat, 03 Oct 2026 08:15:30 +0000"

// Components
let e = @dateku.make_epoch(2026, 10, 3, hour=8, minute=15, second=30)
@dateku.year(e)     // 2026
@dateku.hour(e)     // 8

// Shifts and day queries
let tomorrow = @dateku.add_days(e, 1)
@dateku.is_same_day(e, tomorrow)              // false
@dateku.start_of_day(e) == @dateku.make_epoch(2026, 10, 3)  // true

// Calendar
@dateku.is_leap_year(2024)        // true
@dateku.days_in_month(2026, 2)    // 28
```

</details>

## Author

**陈随易** ([@chenbimo](https://github.com/chenbimo)) · [mooncakes: chensuiyi](https://mooncakes.io/user/chensuiyi)

## License

MIT

<details>
<summary><strong>中文文档</strong></summary>

# chensuiyi/dateku

MoonBit 时间戳库:ISO 8601 / RFC 5322 格式化、UTC 分量读取、构造、平移与日历查询,仅 UTC。

## 安装

```bash
moon add chensuiyi/dateku
```

## 功能

- `iso8601` / `rfc5322`:civil-from-days 算法,闰世纪规则与毫秒边界均有测试
- 分量读取:`year` / `month` / `day` / `hour` / `minute` / `second` / `millisecond`
- `make_epoch`:按 UTC 分量构造,越界分量自然进位;与 `iso8601` 精确互逆
- 平移:`add_days` / `add_hours` / `add_minutes` / `add_seconds`(负数回退)
- 日查询:`start_of_day` / `is_same_day`;日历:`is_leap_year` / `days_in_month`
- 刻意不做:时区、本地化、解析

## 场景

- 日志行时间戳(ISO 8601)
- 邮件 Date 头(RFC 5322)
- 状态行与 TTL 窗口:按时/天平移、同日判定

## API

| 函数 | 说明 |
| --- | --- |
| `now_ms()` | 当前 epoch 毫秒 |
| `now_unix()` | 当前 epoch 秒 |
| `iso8601(epoch_ms)` | `2026-10-03T08:15:30.123Z` |
| `rfc5322(epoch_ms)` | `Sat, 03 Oct 2026 08:15:30 +0000` |
| `year(epoch_ms)` | UTC 年 |
| `month(epoch_ms)` | UTC 月,1-12 |
| `day(epoch_ms)` | UTC 日,1-31 |
| `hour(epoch_ms)` | UTC 时,0-23 |
| `minute(epoch_ms)` | UTC 分,0-59 |
| `second(epoch_ms)` | UTC 秒,0-59 |
| `millisecond(epoch_ms)` | UTC 毫秒,0-999 |
| `make_epoch(y, m, d, ...)` | 构造 epoch 毫秒,分量越界进位 |
| `is_leap_year(y)` | 格里高利闰年 |
| `days_in_month(y, m)` | 28-31,月份非法返回 0 |
| `add_days / add_hours / add_minutes / add_seconds(e, n)` | 平移,负数回退 |
| `start_of_day(e)` | 当日 UTC 零点 |
| `is_same_day(a, b)` | 同一 UTC 日 |

## 用法示例

```moonbit
@dateku.iso8601(1791015330123UL)   // "2026-10-03T08:15:30.123Z"
@dateku.rfc5322(1791015330000UL)   // "Sat, 03 Oct 2026 08:15:30 +0000"

// 分量读取
let e = @dateku.make_epoch(2026, 10, 3, hour=8, minute=15, second=30)
@dateku.year(e)     // 2026
@dateku.hour(e)     // 8

// 平移与日查询
let tomorrow = @dateku.add_days(e, 1)
@dateku.is_same_day(e, tomorrow)              // false
@dateku.start_of_day(e) == @dateku.make_epoch(2026, 10, 3)  // true

// 日历
@dateku.is_leap_year(2024)        // true
@dateku.days_in_month(2026, 2)    // 28
```

## 作者

**陈随易** ([@chenbimo](https://github.com/chenbimo))

## 协议

MIT

</details>
