# TableViewControllerCoverKit

A scrolling cover image for **any** `UITableView` — list content scrolls over an image that sits behind it with a once‑rendered vignette, stretches with a spring on overscroll, and a navigation bar that fades in as you scroll past it.

Attaches by **composition**, not subclassing: keep your plain `UITableViewController` and hand the cover a reference to its table view. It observes scrolling itself (KVO), so it never touches your scroll delegate — and removing it leaves a standard table view.

## Requirements
iOS 17 · Swift 5.9

## Installation
```swift
.package(url: "https://github.com/A-bv/TableViewControllerCoverKit", from: "3.0.0")
```

## Usage
```swift
import TableViewControllerCoverKit

final class MyListViewController: UITableViewController {
    private lazy var cover = CoverImageController(tableView: tableView, host: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        cover.setCoverImage(UIImage(named: "cover"))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cover.applyBarAppearance()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { cover.preferredStatusBarStyle }
}
```

Tunables: `coverCornerRadius`, `expandedBarHeight`, `barBackgroundColor`. Set `suspendsCoverStatusBarStyle` while presenting a modal so the status bar reads normally.

> The status‑bar line is the only thing UIKit forces through the view controller; everything else (cover, vignette, fade, stretch) the controller handles on its own.
