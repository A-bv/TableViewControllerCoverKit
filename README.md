# TableViewControllerCoverKit

A `UITableViewController` whose list scrolls over a cover image — with a vignette, a navigation bar that fades in, and a spring stretch on overscroll. Requires iOS 15+.

<p align="center">
  <img src="Docs/demo-default.gif" width="260" alt="Cover effect demo">
</p>

## Installation

Swift Package Manager:

```swift
.package(url: "https://github.com/A-bv/TableViewControllerCoverKit", from: "5.0.0")
```

## Usage

Subclass `CoverImageTableViewController`, set a cover image, and drive the list like any `UITableViewController`. Present it inside a `UINavigationController`:

```swift
import TableViewControllerCoverKit

final class MyListViewController: CoverImageTableViewController {
    private let items = ["One", "Two", "Three"]

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cover"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        setCoverImage(UIImage(named: "cover"))
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        var config = cell.defaultContentConfiguration()
        config.text = items[indexPath.row]
        cell.contentConfiguration = config
        return cell
    }
}
```

## License

MIT — see [LICENSE](LICENSE).
