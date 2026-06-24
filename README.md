# TableViewControllerCoverKit

[![CI](https://github.com/A-bv/TableViewControllerCoverKit/actions/workflows/ci.yml/badge.svg)](https://github.com/A-bv/TableViewControllerCoverKit/actions/workflows/ci.yml)
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
![Platforms](https://img.shields.io/badge/Platforms-iOS%2015%2B-blue.svg)
![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

A `UITableViewController` subclass that renders your table list over a cover image with a gorgeous fade effect, navigation bar that transitions in, and a spring stretch on overscroll.

<p align="center">
  <img src="Docs/demo-default.gif" width="260">
</p>

## Installation

### Swift Package Manager

Add this package in Xcode: **File → Add Packages** and enter:
```
https://github.com/A-bv/TableViewControllerCoverKit
```

Or add this to your `Package.swift`:

```swift
.package(url: "https://github.com/A-bv/TableViewControllerCoverKit", from: "6.0.0")
```

## Quick Start

Subclass `CoverImageTableViewController`, present it in a `UINavigationController`, set your cover image, and implement the standard table view data source methods:

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
