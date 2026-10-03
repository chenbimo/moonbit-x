name = "chensuiyi/subproc"

version = "0.1.0"

source = "src"

preferred_target = "native"

supported_targets = "native"

license = "MIT"

readme = "README.md"

description = "Synchronous process management for MoonBit: spawn with env/cwd/redirection, waitpid and pidfd waits, kill, procfs sampling and platform probes"

keywords = [ "process", "spawn", "pidfd", "procfs", "signal" ]

repository = "https://github.com/chenbimo/moonbit"

import {
  "chensuiyi/fsx@0.1.0",
  "chensuiyi/fndash@0.1.0",
}
