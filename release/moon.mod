name = "chensuiyi/release"

version = "0.1.0"

source = "src"

preferred_target = "native"

supported_targets = "native"

license = "MIT"

readme = "README.md"

description = "moon.work 多模块发布编排:版本递增 → 依赖排序 → 逐个 moon publish → moon work sync"

keywords = [ "release", "publish", "workspace", "moon.work" ]

import {
  "moonbitlang/async@0.22.4",
  "moonbitlang/x@0.5.1",
  "chensuiyi/fndash@0.1.0",
  "chensuiyi/semver@0.1.0",
}
