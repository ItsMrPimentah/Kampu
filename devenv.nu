# Flutter workflows run from the repository root using the FVM-pinned SDK.
if (sys host | get name) == 'Darwin' {
  $env.PATH = ($env.PATH | prepend '/usr/bin' | prepend '/bin')
  hide-env DEVELOPER_DIR
  $env.DEVELOPER_DIR = (^/usr/bin/xcode-select -p | str trim)
  $env.SDKROOT = (^/usr/bin/xcrun --sdk macosx --show-sdk-path | str trim)
}

export def format [] {
  cd apps/mobile
  ^fvm dart format lib test tool
}

export def test [] {
  cd apps/mobile
  ^fvm flutter test
}

export def analyze [] {
  cd apps/mobile
  ^fvm dart format --output=none --set-exit-if-changed lib test tool
  if $env.LAST_EXIT_CODE != 0 { exit $env.LAST_EXIT_CODE }
  ^fvm dart run tool/check_layer_imports.dart
  if $env.LAST_EXIT_CODE != 0 { exit $env.LAST_EXIT_CODE }
  ^fvm flutter analyze
}
