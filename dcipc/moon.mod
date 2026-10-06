name = "chensuiyi/dcipc"

version = "0.3.0"

source = "src"

preferred_target = "native"

supported_targets = "native"

license = "MIT"

readme = "README.md"

description = "Local daemon control channel for MoonBit: length-prefixed frames, token auth over loopback TCP, contact files in the state dir"

keywords = [ "ipc", "daemon", "frame", "token", "tcp" ]

repository = "https://github.com/chenbimo/moonbit"

import {
  "moonbitlang/async@0.22.4",
  "chensuiyi/fsx@0.3.0",
}
