# TableViewControllerCoverKit

A `UITableViewController` whose content scrolls over a cover image — the image sits behind the list with a once‑rendered vignette, stretches with a spring on overscroll, and a navigation bar that fades in as you scroll past it.

Subclass it and hand it an image; that's the whole API. Remove the package and swap the superclass back to `UITableViewController` for a standard list.

## Requirements
iOS 17 · Swift 5.9

## Installation
```swift
.package(url: "https://github.com/A-bv/TableViewControllerCoverKit", from: "5.0.0")
```

## Usage
```swift
import TableViewControllerCoverKit

final class MyListViewController: CoverImageTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setCoverImage(UIImage(named: "cover"))
    }
}
```

The base class owns the rest: the bar fades in as the list scrolls over the image, and the status bar reads light while the bar floats over the cover. Tunables: `coverCornerRadius`, `expandedBarHeight`, `barBackgroundColor`. Set `suspendsCoverStatusBarStyle` while presenting a modal so the status bar reads normally.

A scrollable `#Preview` ships with the package — open it in Xcode to see the fade + stretch without an app.
