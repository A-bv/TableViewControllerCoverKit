# TableViewControllerCoverKit

A `UITableViewController` whose content scrolls over a cover image. The image sits behind the list with a once-rendered vignette, stretches with a spring effect when the user overscrolls, and the list content starts below the image's visible half.

## Usage

```swift
import TableViewControllerCoverKit

final class MyListViewController: CoverImageTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setCoverImage(UIImage(named: "cover"))   // the whole API
    }
}
```

The class owns the full customization: the navigation bar fades in as the list scrolls over the image, and the status bar reads light while the bar floats over the cover. Tunables: `coverCornerRadius`, `expandedBarHeight`, `barBackgroundColor`. Flip `suspendsCoverStatusBarStyle` while presenting a modal so the status bar reads normally.
