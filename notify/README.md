# chensuiyi/notify

Multi-platform notification library for MoonBit: seven platform presets (Feishu / DingTalk / WeCom / Slack / Discord / generic webhook / SMTP email), HTTP & SMTP delivery, and an optional dedupe / rate-limit / retry engine.

## Install

```bash
moon add chensuiyi/notify
```

## Platforms

| preset | Platform | Transport |
| --- | --- | --- |
| `feishu` | Feishu | HTTPS (optional signing) |
| `dingtalk` | DingTalk | HTTPS (HMAC signing) |
| `wecom` | WeCom | HTTPS |
| `slack` | Slack | HTTPS |
| `discord` | Discord | HTTPS |
| `webhook` | Generic webhook | HTTPS (Bearer) |
| `email` | Email | SMTP (STARTTLS / smtps) |

## Usage

```moonbit
// One-shot delivery: None = success, Some(reason) = failure (credential-free)
let failure = deliver(target, msg, 5000, { host: "prod-1", product: "myapp" })
```

```moonbit
// Optional engine: dedupe → rate-limit → queue → retry with backoff
let engine = Engine::new({ host: "prod-1", product: "myapp" })
engine.emit(
  now, "crash|api", "api", msg, targets, 5000,
  dedupe_window_s=3600, rate_per_minute=30, queue_limit=128,
)
let report = engine.pump(now) // call once per tick
```

## API

| Interface | Description |
| --- | --- |
| `deliver(target, msg, timeout_ms, ctx)` | Deliver one message to a single target |
| `deliver_all(targets, msg, timeout_ms, ctx)` | Deliver to each target, returns `(name, failure)` list |
| `Engine::new(ctx, max_attempts?)` | Create the engine |
| `Engine::emit(...)` | Enqueue a message, returns `Queued / Deduped / RateLimited / QueueFull` |
| `Engine::pump(now)` | Deliver the queue head, returns `remaining / outcome / owner` |
| `Engine::dropped()` / `Engine::queued()` | Drop and queue counters |

Design contract: credential-free failures (reasons never contain url / secret / password), caller-injected time, no logging no disk.

## Dependencies

- `moonbitlang/async@0.22.4` (HTTP / SMTP / timeouts)
- `moonbitlang/x@0.5.1` (HMAC signing)
- `moonbitlang/moon_config` — no; deps are `chensuiyi/dateku@0.1.0` + `chensuiyi/fndash@0.1.0`

<details>
<summary><strong>中文说明</strong></summary>

# chensuiyi/notify

MoonBit 多平台通知库:七种平台预设(飞书/钉钉/企业微信/Slack/Discord/通用 webhook/SMTP 邮件)、HTTP 与 SMTP 投递、可选的去重/限流/重试引擎。

## 平台

| preset | 平台 | 传输 |
| --- | --- | --- |
| `feishu` | 飞书 | HTTPS(可选签名) |
| `dingtalk` | 钉钉 | HTTPS(HMAC 签名) |
| `wecom` | 企业微信 | HTTPS |
| `slack` | Slack | HTTPS |
| `discord` | Discord | HTTPS |
| `webhook` | 通用 webhook | HTTPS(Bearer) |
| `email` | 邮件 | SMTP(STARTTLS / smtps) |

## 设计约定

- **凭据不泄露**——失败原因永不包含 url / secret / password,可放心打进日志
- **时间由调用方注入**——库不读时钟,完全可测
- **不写日志不落盘**——只投递并返回结构化结果

## 用法

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

## 依赖

- `moonbitlang/async@0.22.4`(HTTP / SMTP / 超时)
- `moonbitlang/x@0.5.1`(HMAC 签名)
- `chensuiyi/dateku@0.1.0` + `chensuiyi/fndash@0.1.0`

</details>

## License

MIT
