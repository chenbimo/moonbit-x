# dateku

MoonBit 日期时间格式化库:epoch 毫秒 → ISO 8601 / RFC 5322 时间戳,仅 UTC。

```moonbit
@dateku.now_ms()                      // 当前 epoch 毫秒
@dateku.iso8601(1790985600123UL)      // "2026-10-03T00:00:00.123Z"
@dateku.rfc5322(1790985600000UL)      // "Sat, 03 Oct 2026 00:00:00 +0000"
```

- `iso8601`:civil-from-days 算法(Howard Hinnant,公有领域),闰年/跨年/跨日边界均有测试
- `rfc5322`:邮件 Date 头格式,含星期与月份英文名
- 刻意不做:时区转换、本地化、解析(v2 按需)

## License

MIT
