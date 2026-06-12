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

`coverCornerRadius` and `expandedBarHeight` are tunable. Navigation-bar styling is deliberately out of scope — override `scrollViewDidScroll` (calling `super`) to drive your own chrome from the scroll position.
