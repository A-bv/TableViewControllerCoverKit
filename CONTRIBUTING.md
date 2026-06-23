# Contributing

Thanks for your interest — this is a small, focused package, so contributions are easy to review.

- **Issues:** include the device, iOS version, and steps to reproduce.
- **Pull requests:** keep them focused. Run the tests and add one for any behavior change:

  ```sh
  xcodebuild test -scheme TableViewControllerCoverKit \
    -destination 'platform=iOS Simulator,name=iPhone 16'
  ```

- The package targets **iOS 15+**, stays **UIKit-only and dependency-free**, and is **portrait-oriented** by design. Match the existing style and keep it simple.
