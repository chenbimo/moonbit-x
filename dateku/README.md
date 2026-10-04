# chensuiyi/dateku

Epoch milliseconds → ISO 8601 / RFC 5322 timestamps for MoonBit, UTC only.

<details>
<summary><strong>中文文档</strong></summary>

## 简介

epoch 毫秒 → ISO 8601 / RFC 5322 时间戳,仅 UTC。

## 功能

- `iso8601`:civil-from-days 算法,闰世纪规则与毫秒边界均有测试
- `rfc5322`:邮件 Date 头(星期/月份英文名)

## 场景

- 日志行时间戳
- 邮件 Date 头

</details>

## Features

- `iso8601`: civil-from-days algorithm; leap-century rules and millisecond boundaries tested
- `rfc5322`: email Date header with spelled-out weekday and month names
- Deliberately out of scope: timezones, localization, parsing

## Scenarios

- Log line timestamps (ISO 8601)
- Email `Date` headers (RFC 5322)

## API

| Function | Description |
| --- | --- |
| `now_ms()` | Current epoch milliseconds |
| `iso8601(epoch_ms)` | `2026-10-03T08:15:30.123Z` |
| `rfc5322(epoch_ms)` | `Sat, 03 Oct 2026 08:15:30 +0000` |

<details>
<summary><strong>用法示例 / usage</strong></summary>

```moonbit
@dateku.iso8601(1790998530123UL)   // "2026-10-03T08:15:30.123Z"
@dateku.rfc5322(1790998530000UL)   // "Sat, 03 Oct 2026 08:15:30 +0000"
```

</details>

## Author

**陈随易** ([@chenbimo](https://github.com/chenbimo)) · [mooncakes: chensuiyi](https://mooncakes.io/user/chensuiyi)

## License

MIT
