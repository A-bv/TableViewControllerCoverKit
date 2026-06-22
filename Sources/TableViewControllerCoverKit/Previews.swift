import SwiftUI
import UIKit

// Scrollable living preview: a list with a sample cover so you can verify the fade +
// spring-stretch directly in Xcode's canvas, no host app needed. Scroll up to see the
// bar fade in; pull down to see the cover stretch.
#Preview("Cover") {
    UINavigationController(rootViewController: CoverDemoListController())
}

private final class CoverDemoListController: UITableViewController {
    private lazy var cover = CoverImageController(tableView: tableView, host: self)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cover"
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        cover.barBackgroundColor = .systemBackground
        cover.setCoverImage(Self.sampleCover())
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cover.applyBarAppearance()
    }

    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        cover.scrollViewDidScroll()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { cover.preferredStatusBarStyle }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 30 }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row + 1)"
        return cell
    }

    private static func sampleCover() -> UIImage {
        let size = CGSize(width: 600, height: 800)
        return UIGraphicsImageRenderer(size: size).image { context in
            let colors = [UIColor.systemIndigo.cgColor, UIColor.systemTeal.cgColor] as CFArray
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1])!
            context.cgContext.drawLinearGradient(
                gradient, start: .zero, end: CGPoint(x: size.width, y: size.height), options: [])
        }
    }
}
