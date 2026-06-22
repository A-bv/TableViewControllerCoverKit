#if DEBUG
import SwiftUI
import UIKit

// Scrollable living preview: a list with a sample cover. Scroll up to see the bar fade
// in; pull down to see the cover stretch. Uses `PreviewProvider` (not the `#Preview`
// macro) so the package stays iOS 15+.
struct Cover_Previews: PreviewProvider {
    static var previews: some View {
        CoverPreview().ignoresSafeArea()
    }

    private struct CoverPreview: UIViewControllerRepresentable {
        func makeUIViewController(context: Context) -> UIViewController {
            UINavigationController(rootViewController: CoverDemoListController())
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    }
}

private final class CoverDemoListController: CoverImageTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cover"
        // Defaults to a standard title bar. Large titles are supported too — set
        // `navigationController?.navigationBar.prefersLargeTitles = true` to opt in.
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        barBackgroundColor = .systemBackground
        setCoverImage(Self.sampleCover())
    }

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
#endif
