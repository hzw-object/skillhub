#!/usr/bin/env bash
# Swift Testing runner for SkillHub (CLT-only env, no Xcode).
# The Testing.framework and libTestingMacros.dylib ship with Command Line Tools
# but SwiftPM doesn't search their paths by default, so wire them up here.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

exec swift test \
  -Xswiftc -F -Xswiftc /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xswiftc -load-plugin-library -Xswiftc /Library/Developer/CommandLineTools/usr/lib/swift/host/plugins/testing/libTestingMacros.dylib \
  -Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/usr/lib \
  "$@"
