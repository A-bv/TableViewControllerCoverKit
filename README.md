# TableViewControllerCoverKit

A `UITableViewController` whose content scrolls over a cover image — the image sits behind the list with a once‑rendered vignette, stretches with a spring on overscroll, and a navigation bar that fades in as the list scrolls up over it.

Subclass it and hand it an image; the list itself stays a plain `UITableViewController`. Remove the package and swap the superclass back to `UITableViewController` for a standard list.

## Demo

<table>
  <tr>
    <td align="center"><b>Default (standard title)</b></td>
    <td align="center"><b>Large titles</b></td>
  </tr>
  <tr>
    <td><img src="Docs/demo-default.gif" width="250" alt="Standard title bar fading in over the cover, with a spring stretch on overscroll"></td>
    <td><img src="Docs/demo-large-title.gif" width="250" alt="Large-title variant of the same screen"></td>
  </tr>
</table>

## Requirements

iOS 15

## Installation

Swift Package Manager:

```swift
.package(url: "https://github.com/A-bv/TableViewControllerCoverKit", from: "5.0.0")
```

## Usage

Subclass `CoverImageTableViewController`, give it a cover image, and **present it inside a `UINavigationController`** — the bar fade and the light status bar over the cover rely on having a navigation bar:

```swift
import TableViewControllerCoverKit

final class MyListViewController: CoverImageTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cover"
        setCoverImage(UIImage(named: "cover"))
    }
}

// somewhere in your scene/app setup:
window.rootViewController = UINavigationController(rootViewController: MyListViewController())
```

The base class owns the cover: the vignette, the spring stretch on overscroll, and the bar that fades in as the list scrolls up over the image while the status bar reads light over the cover.

## Populating the list

`CoverImageTableViewController` only adds the cover — the list is still an ordinary `UITableViewController`, so you drive it with the normal data source. Register a cell and override the usual methods:

```swift
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

Custom cells, diffable data sources, and `UITableViewDelegate` callbacks all work exactly as they do on a plain `UITableViewController`.

## Large titles

The bar defaults to a standard title and works the same on every device. Large titles are supported too — opt in as usual:

```swift
navigationController?.navigationBar.prefersLargeTitles = true
```

With large titles the bar fades in step with the title collapsing into its inline position — the same coupling the system uses — which naturally lands a little earlier in the scroll than the standard-title fade.

## Customization

| Property | Default | Effect |
| --- | --- | --- |
| `coverCornerRadius` | `22` | Corner radius where the list meets the image. |
| `expandedBarHeight` | `96` | Estimated expanded-bar height used to place the content's top edge. |
| `barBackgroundColor` | `.systemBackground` | The bar's background once it has fully faded in. |
| `suspendsCoverStatusBarStyle` | `false` | Set while presenting a modal so the status bar reads normally. |

## Preview

A scrollable `#Preview` ships with the package — open `Previews.swift` in Xcode to see the fade and stretch without building an app.
