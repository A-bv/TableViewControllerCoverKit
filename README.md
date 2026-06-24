# TableViewControllerCoverKit

[![CI](https://github.com/A-bv/TableViewControllerCoverKit/actions/workflows/ci.yml/badge.svg)](https://github.com/A-bv/TableViewControllerCoverKit/actions/workflows/ci.yml)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%2B-blue.svg)
![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

A `UITableViewController` whose list scrolls over a cover image — vignette, a navigation bar that fades in, and a spring stretch on overscroll. iOS 15+.

<p align="center">
  <img src="Docs/demo-default.gif" width="260">
</p>

## Installation

```swift
.package(url: "https://github.com/A-bv/TableViewControllerCoverKit", from: "5.0.0")
```

## Usage

Subclass `CoverImageTableViewController`, present it in a `UINavigationController`, set a cover image, and fill the list as usual:

```swift
import TableViewControllerCoverKit

final class MyList: CoverImageTableViewController {
    private let items = ["One", "Two", "Three"]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        setCoverImage(UIImage(named: "cover"))
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}
```

## License

MIT
