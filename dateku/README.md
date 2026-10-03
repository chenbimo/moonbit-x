# chensuiyi/dateku

Date-time formatting · 日期时间格式化

<table>
<tr>
<th width="50%">中文</th>
<th width="50%">English</th>
</tr>
<tr>
<td valign="top">

epoch 毫秒 → ISO 8601 / RFC 5322 时间戳,仅 UTC。

- `iso8601`:civil-from-days 算法,闰世纪规则与毫秒边界均有测试
- `rfc5322`:邮件 Date 头(星期/月份英文名)
- 刻意不做:时区、本地化、解析(v2 按需)

</td>
<td valign="top">

Epoch milliseconds → ISO 8601 / RFC 5322 timestamps, UTC only.

- `iso8601`: civil-from-days algorithm (Howard Hinnant, public domain); leap-century rules and millisecond boundaries are tested
- `rfc5322`: email Date header with spelled-out weekday and month names
- Deliberately out of scope: timezones, localization, parsing (v2 if needed)

</td>
</tr>
</table>

## API

| 接口 Interface | 说明 Description |
| --- | --- |
| `now_ms()` | 当前 epoch 毫秒;Current epoch milliseconds |
| `iso8601(epoch_ms)` | `2026-10-03T08:15:30.123Z` |
| `rfc5322(epoch_ms)` | `Sat, 03 Oct 2026 08:15:30 +0000` |

License: MIT
