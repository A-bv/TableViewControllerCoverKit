# Contributing

Thanks for your interest — this is a small, focused package, so contributions are easy to review.

- **Issues:** include the device, iOS version, and steps to reproduce.
- **Pull requests:** keep them focused, and add a test for any behavior change.

  The package is **UIKit-based, so the tests only run on an iOS simulator** — `swift test` builds for macOS and fails with `no such module 'UIKit'`. Run:

  ```sh
  xcodebuild test -scheme TableViewControllerCoverKit \
    -destination 'platform=iOS Simulator,name=iPhone 16'
  ```

  Or open the package in Xcode, choose an iOS Simulator, and press ⌘U.

- The package targets **iOS 15+**, stays **UIKit-only and dependency-free**, and is **portrait-oriented** by design. Match the existing style and keep it simple.
