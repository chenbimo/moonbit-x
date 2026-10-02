name = "chensuiyi/notify"

version = "0.2.0"

source = "src"

preferred_target = "native"

supported_targets = "native"

license = "MIT"

readme = "README.md"

description = "MoonBit 通知库:多平台 webhook(飞书/钉钉/企业微信/Slack/Discord)、通用 webhook、SMTP 邮件,含去重/限流/重试引擎"

keywords = [ "notify", "webhook", "feishu", "dingtalk", "smtp" ]

repository = "https://github.com/chenbimo/moonbit"

import {
  "moonbitlang/async@0.22.4",
  "moonbitlang/x@0.5.1",
}
