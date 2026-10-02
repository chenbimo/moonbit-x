# chensuiyi/notify

MoonBit 多平台通知库 · Multi-platform notification library for MoonBit

<table>
<tr>
<th width="50%">中文</th>
<th width="50%">English</th>
</tr>
<tr>
<td valign="top">

### 简介

一个库覆盖通知的完整链路:消息模型、七种平台预设、HTTP/SMTP 投递,以及可选的去重/限流/重试引擎。

设计约定:

- **凭据不泄露**——失败原因永不包含 url / secret / password,可放心打进日志
- **时间由调用方注入**——库不读时钟,完全可测
- **不写日志不落盘**——只投递并返回结构化结果

</td>
<td valign="top">

### Intro

One library for the whole notification path: a message model, seven platform presets, HTTP/SMTP delivery, and an optional dedupe / rate-limit / retry engine.

Design contract:

- **Credential-free failures** — failure reasons never contain url / secret / password, safe to log
- **Caller-injected time** — the library never reads a clock, fully testable
- **No logging, no disk** — delivers and returns structured results

</td>
</tr>
</table>

## 平台 Platforms

| preset | 平台 Platform | 传输 Transport |
| --- | --- | --- |
| `feishu` | 飞书 | HTTPS(可选签名) |
| `dingtalk` | 钉钉 | HTTPS(HMAC 签名) |
| `wecom` | 企业微信 | HTTPS |
| `slack` | Slack | HTTPS |
| `discord` | Discord | HTTPS |
| `webhook` | 通用 webhook | HTTPS(Bearer) |
| `email` | 邮件 | SMTP(STARTTLS / smtps) |

## 用法 Usage

```moonbit
// 一次性投递:None = 成功,Some(reason) = 失败原因(不含凭据)
let failure = deliver(target, msg, 5000, { host: "prod-1", product: "myapp" })
```

```moonbit
// 可选引擎:去重 → 限流 → 队列 → 失败退避重试
let engine = Engine::new({ host: "prod-1", product: "myapp" })
engine.emit(
  now, "crash|api", "api", msg, targets, 5000,
  dedupe_window_s=3600, rate_per_minute=30, queue_limit=128,
)
let report = engine.pump(now) // 每 tick 调用一次
```

## API

| 接口 | 说明 |
| --- | --- |
| `deliver(target, msg, timeout_ms, ctx)` | 投递一条消息到单个目标 |
| `deliver_all(targets, msg, timeout_ms, ctx)` | 逐个投递,返回 `(name, failure)` 列表 |
| `Engine::new(ctx, max_attempts?)` | 创建引擎 |
| `Engine::emit(...)` | 入队一条消息,返回 `Queued / Deduped / RateLimited / QueueFull` |
| `Engine::pump(now)` | 投递队首消息,返回 `remaining / outcome / owner` |
| `Engine::dropped()` / `Engine::queued()` | 丢弃与排队计数 |

限流窗口按 `owner` 独立,计数发生在入队时——失败端点不会绕过限流。

## 依赖 Dependencies

- `moonbitlang/async@0.22.4`(HTTP / SMTP / 超时)
- `moonbitlang/x@0.5.1`(HMAC 签名)

License: MIT
